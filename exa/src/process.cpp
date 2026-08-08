#include "process.h"
#include <libproc.h>
#include <mach-o/loader.h>
#include <spdlog/spdlog.h>

auto Process::attach(const std::string& process_name) -> bool {
    int pid = 0;
    int count = proc_listpids(PROC_ALL_PIDS, 0, nullptr, 0);
    if (count <= 0) return false;

    std::vector<pid_t> pids(count);
    count = proc_listpids(PROC_ALL_PIDS, 0, pids.data(), count);

    for (int i = 0; i < count; ++i) {
        if (pids[i] <= 0) continue;

        char buffer[PROC_PIDPATHINFO_MAXSIZE];
        int len = proc_pidpath(pids[i], buffer, sizeof(buffer));
        if (len <= 0) continue;

        std::string path(buffer, len);
        if (path.find(process_name) != std::string::npos) {
            mach_port_t task = TASK_NULL;
            kern_return_t kr = task_for_pid(mach_task_self(), pids[i], &task);
            if (kr == KERN_SUCCESS) {
                m_task = task;
                m_pid = pids[i];
                spdlog::info("Attached to {} (PID: {})", process_name, m_pid);

                if (!find_module_base()) {
                    spdlog::warn("Failed to find module base, pointer offsets may be wrong");
                }

                return true;
            }
        }
    }

    spdlog::error("Failed to find or attach to {}", process_name);
    return false;
}

auto Process::find_module_base() -> bool {
    mach_vm_address_t address = 0;
    mach_vm_size_t size = 0;
    vm_region_basic_info_data_64_t info{};
    mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
    mach_port_t object_name = MACH_PORT_NULL;

    while (true) {
        kern_return_t kr = mach_vm_region(
            m_task,
            &address,
            &size,
            VM_REGION_BASIC_INFO_64,
            reinterpret_cast<vm_region_info_t>(&info),
            &count,
            &object_name
        );

        if (kr != KERN_SUCCESS) break;

        if (info.protection & VM_PROT_EXECUTE) {
            uint32_t magic = 0;
            auto magic_read = read<uint32_t>(address);
            if (magic_read) {
                magic = *magic_read;

                if (magic == MH_MAGIC_64 || magic == MH_CIGAM_64) {
                    m_module_base = address;
                    spdlog::info("Module base (Mach-O): 0x{:X} (size: 0x{:X})", address, size);
                    return true;
                }
            }
        }

        address += size;
    }

    address = 0;
    while (true) {
        kern_return_t kr = mach_vm_region(
            m_task,
            &address,
            &size,
            VM_REGION_BASIC_INFO_64,
            reinterpret_cast<vm_region_info_t>(&info),
            &count,
            &object_name
        );

        if (kr != KERN_SUCCESS) break;

        if (info.protection & VM_PROT_READ && info.shared == 0) {
            m_module_base = address;
            spdlog::info("Module base (first readable private): 0x{:X} (size: 0x{:X})", address, size);
            return true;
        }

        address += size;
    }

    return false;
}

auto Process::detach() -> void {
    if (m_task != TASK_NULL) {
        mach_port_deallocate(mach_task_self(), m_task);
        m_task = TASK_NULL;
    }
    m_pid = 0;
    m_module_base = 0;
}

auto Process::read_string(uintptr_t address, size_t max_len) const -> std::optional<std::string> {
    if (!address) return std::nullopt;

    std::string result;
    result.reserve(max_len);

    for (size_t i = 0; i < max_len; ++i) {
        auto ch = read<char>(address + i);
        if (!ch || *ch == '\0') break;
        result.push_back(*ch);
    }

    return result.empty() ? std::nullopt : std::make_optional(result);
}

auto Process::read_sso_string(uintptr_t address) const -> std::optional<std::string> {
    if (!address) return std::nullopt;

    std::array<uint8_t, 24> bytes{};
    for (size_t i = 0; i < 24; ++i) {
        auto b = read<uint8_t>(address + i);
        if (!b) return std::nullopt;
        bytes[i] = *b;
    }

    auto read_qword = [&](size_t offset) -> uintptr_t {
        uintptr_t val = 0;
        std::memcpy(&val, bytes.data() + offset, sizeof(val));
        return val;
    };

    auto try_read_inline = [&](size_t data_offset, size_t len) -> std::optional<std::string> {
        if (len == 0 || len > 22) return std::nullopt;
        std::string val(reinterpret_cast<const char*>(bytes.data() + data_offset), len);
        for (char c : val) {
            if (c < 0x20 || c > 0x7E) return std::nullopt;
        }
        return val;
    };

    if (bytes[0] <= 23) {
        if (auto v = try_read_inline(1, bytes[0])) return v;
    }

    if ((bytes[0] & 1U) == 0 && (bytes[0] >> 1) <= 23) {
        if (auto v = try_read_inline(1, bytes[0] >> 1)) return v;
    }

    if (bytes[23] <= 23) {
        if (auto v = try_read_inline(0, bytes[23])) return v;
    }

    if ((bytes[23] & 1U) == 0 && (bytes[23] >> 1) <= 23) {
        if (auto v = try_read_inline(0, bytes[23] >> 1)) return v;
    }

    auto try_external = [&](size_t ptr_offset, size_t size_offset) -> std::optional<std::string> {
        auto sz = read_qword(size_offset);
        auto ptr = read_qword(ptr_offset);
        if (ptr >= 0x10000 && sz > 0 && sz < 4096) {
            return read_string(ptr, sz);
        }
        return std::nullopt;
    };

    if (auto v = try_external(0x00, 0x08)) return v;
    if (auto v = try_external(0x08, 0x10)) return v;

    return std::nullopt;
}
