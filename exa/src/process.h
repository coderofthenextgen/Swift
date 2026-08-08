#pragma once
#include <cstdint>
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <string>

class Process {
public:
    auto attach(const std::string& process_name) -> bool;
    auto detach() -> void;

    template <typename T>
    auto read(uintptr_t address) const -> std::optional<T> {
        if (!address) return std::nullopt;

        T value{};
        mach_vm_size_t count = sizeof(T);
        auto result = mach_vm_read_overwrite(
            m_task,
            address,
            sizeof(T),
            reinterpret_cast<mach_vm_address_t>(&value),
            &count
        );

        if (result != KERN_SUCCESS) return std::nullopt;
        return value;
    }

    template <typename T>
    auto write(uintptr_t address, const T& value) const -> bool {
        if (!address) return false;
        auto result = mach_vm_write(
            m_task,
            address,
            reinterpret_cast<vm_offset_t>(&value),
            sizeof(T)
        );
        return result == KERN_SUCCESS;
    }

    auto read_string(uintptr_t address, size_t max_len = 64) const -> std::optional<std::string>;
    auto read_sso_string(uintptr_t address) const -> std::optional<std::string>;

    auto is_attached() const -> bool { return m_task != TASK_NULL; }
    auto get_pid() const -> pid_t { return m_pid; }
    auto get_module_base() const -> uintptr_t { return m_module_base; }

private:
    auto find_module_base() -> bool;

    task_port_t m_task = TASK_NULL;
    pid_t m_pid = 0;
    uintptr_t m_module_base = 0;
};

inline Process g_process;
