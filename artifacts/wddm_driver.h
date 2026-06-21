#pragma once

#include <windows.h>
#include <d3dkmddi.h>

namespace TitanX5 {

    // Context for the Titan X5 GPU
    struct DeviceContext {
        HANDLE hDevice;
        UINT64 vendorId;
        UINT64 deviceId;
        bool bIsStarted;
        void* pGpuVirtualAddressSpace;
        
        // Hypothetical registers specific to Titan X5
        ULONG ComputeEngineStatus;
        ULONG DisplayEngineStatus;
        
        // Pointer to the Dxgk interface provided by the OS
        DXGKRNL_INTERFACE DxgkInterface;
    };

    // Driver Entry Point for WDDM Miniport
    extern "C" NTSTATUS APIENTRY DriverEntry(
        _In_ PDRIVER_OBJECT DriverObject,
        _In_ PUNICODE_STRING RegistryPath
    );

    // Initialization and Device Management
    NTSTATUS APIENTRY DxgkDdiAddDevice(
        _In_ IN_CONST_PDEVICE_OBJECT PhysicalDeviceObject,
        _Out_ OUT_PPVOID MiniportDeviceContext
    );

    NTSTATUS APIENTRY DxgkDdiStartDevice(
        _In_ IN_CONST_PVOID MiniportDeviceContext,
        _In_ IN_PDXGK_START_INFO DxgkStartInfo,
        _In_ IN_PDXGKRNL_INTERFACE DxgkInterface,
        _Out_ OUT_PULONG NumberOfVideoPresentSources,
        _Out_ OUT_PULONG NumberOfChildren
    );

    NTSTATUS APIENTRY DxgkDdiStopDevice(
        _In_ IN_CONST_PVOID MiniportDeviceContext
    );

    NTSTATUS APIENTRY DxgkDdiRemoveDevice(
        _In_ IN_CONST_PVOID MiniportDeviceContext
    );

    NTSTATUS APIENTRY DxgkDdiResetDevice(
        _In_ IN_CONST_PVOID MiniportDeviceContext
    );

    // Memory Management
    NTSTATUS APIENTRY DxgkDdiCreateAllocation(
        _In_ IN_CONST_HANDLE hAdapter,
        _Inout_ INOUT_PDXGKARG_CREATEALLOCATION pCreateAllocation
    );

    NTSTATUS APIENTRY DxgkDdiDestroyAllocation(
        _In_ IN_CONST_HANDLE hAdapter,
        _In_ IN_CONST_PDXGKARG_DESTROYALLOCATION pDestroyAllocation
    );

    // Command Execution and Scheduling
    NTSTATUS APIENTRY DxgkDdiSubmitCommand(
        _In_ IN_CONST_HANDLE hAdapter,
        _In_ IN_CONST_PDXGKARG_SUBMITCOMMAND pSubmitCommand
    );

    NTSTATUS APIENTRY DxgkDdiPreemptCommand(
        _In_ IN_CONST_HANDLE hAdapter,
        _In_ IN_CONST_PDXGKARG_PREEMPTCOMMAND pPreemptCommand
    );

    // Display / Presentation
    NTSTATUS APIENTRY DxgkDdiPresent(
        _In_ IN_CONST_HANDLE hContext,
        _Inout_ INOUT_PDXGKARG_PRESENT pPresent
    );

    NTSTATUS APIENTRY DxgkDdiSetVidPnSourceAddress(
        _In_ IN_CONST_HANDLE hAdapter,
        _In_ IN_CONST_PDXGKARG_SETVIDPNSOURCEADDRESS pSetVidPnSourceAddress
    );

} // namespace TitanX5
