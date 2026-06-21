import matplotlib.pyplot as plt
import numpy as np

def generate_dashboard():
    # Mock data generation for 100 time steps
    time_steps = np.arange(0, 100)
    
    # Temperature: Base 50C + sinusoidal variation + noise
    temperature = 50 + 20 * np.sin(time_steps * 0.1) + np.random.normal(0, 2, 100)
    
    # Power: Base 12kW + sinusoidal variation + noise
    power = 12 + 2 * np.cos(time_steps * 0.1) + np.random.normal(0, 0.5, 100)
    
    # Utilization: Base 75% + sinusoidal variation + noise, clipped between 0 and 100
    utilization = np.clip(75 + 15 * np.sin(time_steps * 0.2) + np.random.normal(0, 5, 100), 0, 100)

    # Create figure and axes
    fig, axs = plt.subplots(3, 1, figsize=(10, 8), sharex=True)
    fig.suptitle("Titan X5 Wafer-Scale Metrics Telemetry Dashboard", fontsize=16)

    # Temperature Plot
    axs[0].plot(time_steps, temperature, color='tab:red', linewidth=2)
    axs[0].set_ylabel('Temperature (°C)')
    axs[0].set_title('Wafer Temperature')
    axs[0].grid(True, linestyle='--', alpha=0.7)
    axs[0].axhline(85, color='darkred', linestyle='--', label='Critical Temp Threshold')
    axs[0].legend(loc='upper right')

    # Power Plot
    axs[1].plot(time_steps, power, color='tab:orange', linewidth=2)
    axs[1].set_ylabel('Power (kW)')
    axs[1].set_title('Power Consumption')
    axs[1].grid(True, linestyle='--', alpha=0.7)
    axs[1].axhline(15, color='darkorange', linestyle='--', label='Peak Power Limit')
    axs[1].legend(loc='upper right')

    # Utilization Plot
    axs[2].plot(time_steps, utilization, color='tab:blue', linewidth=2)
    axs[2].set_ylabel('Utilization (%)')
    axs[2].set_title('Compute Utilization')
    axs[2].set_xlabel('Time (s)')
    axs[2].grid(True, linestyle='--', alpha=0.7)
    axs[2].set_ylim(0, 105)

    plt.tight_layout()
    plt.subplots_adjust(top=0.9)
    
    # Save the dashboard
    plt.savefig('titan_x5_telemetry_dashboard.png', dpi=300, bbox_inches='tight')
    print("Telemetry dashboard generated and saved as 'titan_x5_telemetry_dashboard.png'")

if __name__ == "__main__":
    generate_dashboard()
