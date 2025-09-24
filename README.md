# fpga_chaotic_chameleon_system
Verilog project of simple chaotic chameleon system implementation in FPGA. Contains a project for Tang Nano 20k board (IDE GoWin), and folder with simulation testbenches for all important modules.

#### References

1. Xueqing Liu, Bo Sang, Chun Wang, Yan Liu, Cuicui Wang, Irfan Ahmad, Timur Karimov, Vyacheslav Rybin, Denis Butusov, and Ning Wang (2025).
   "Chameleon dynamics in a simple 3D system: bifurcation analysis and hardware-based validation".  *International Journal of Bifurcation and Chaos*, under review (state for 24-09-2025)

# Chaotic Chameleon System in FPGA

## Project Overview
This project implements a chaotic oscillator system which was verified on Tang Nano 20k FPGA board. The system models a set of differential equations that exhibit chaotic behavior, using fixed-point arithmetic and CORDIC-based cosine calculations.

<img src="https://github.com/user-attachments/assets/2b4c4116-381c-4e27-9bf2-b3f277088fad" alt="drawing" width="480"/>

<img src="https://github.com/user-attachments/assets/eb2ce059-1c41-4981-9493-621886c59cff" alt="drawing" width="480"/>

## Key Features
- **Chaotic System Simulation**: Implements the chameleon chaotic oscillator system with three state variables ($x$, $y$, $z$). A chameleon chaotic system is a type of system that exhibits a chaotic attractor which can switch between being a hidden attractor and a self-excited attractor, based on the parameter values. In the particluar case, parameter $c$ defines the type of dynamics. 
- **Fixed-Point Arithmetic**: Uses 16-bit fixed-point numbers with 10 fractional bits for calculations.
- **CORDIC Algorithm**: Cosine calculation using 10-stage CORDIC algorithm and argument augmentation to the range [-9π/2, 9π/2].
- **Runge-Kutta Integration**: 2nd-order numerical integration (Heun method) for solving differential equation.
- **FPGA-Optimized Design**: Calculation core controlled by state machine for efficient FPGA implementation.

## Differential Equations
The system implements the following chaotic equations:

$$
\begin{cases}
\frac{dx}{dt} = -y \\
\frac{dy}{dt} = x + cy + az \\
\frac{dz}{dt} = -\mu z + b\cos(\omega y)
\end{cases}
$$

Where:
- $a$, $b$, $c$, $\mu$, $\omega$ are system parameters. Typical values: $a = 2.5$, $b = 1$, $c = -0.01$, $\mu = 1$, $\omega = 1.85$, though parameters have great impact on system dynamics.
- $x$, $y$, $z$ are state variables
- $\cos(\omega Y)$ is calculated using CORDIC
  
Systems shows different dynamics for different initial conditions. Possible example: $(x_0, x_0, z_0) = (0, 5, 0)$.

## Numerical Integration with Heun's Method

Heun's method is a second-order Runge-Kutta method used to solve ordinary differential equations of the form:

$y' = f(t, y), \quad y(t_0) = y_0$

Heun's method is a two stage single-step numerical scheme. 
Given a step size $h$, such as $t_{n+1} = t_n + h$, the method proceeds as follows:

$k_1 = f(t_n, y_n);$

$k_2 = f(t_n + h, y_n + hk_1);$

$y_{n+1} = y_n + \frac{h}{2}(k_1 + k_2).$

For chameleon ODE system under consideration, this results in following. 
First half-step:

$$
\begin{cases}
dX = -Y;\\
dY = X + c Y + a Z;\\
dZ = -\mu Z + b \cos(\omega Y) ;
\end{cases}
$$

Update state variables:

$$
\begin{align}
X_{pred} = X + dX;\\
Y_{pred} = Y + dY;\\
Z_{pred} = Z + dZ;
\end{align}
$$

Second half-step:

$$
\begin{cases}
dX_{pred} = -Y_{pred};\\
dY_{pred} = X_{pred} + c Y_{pred} + a Z_{pred};\\
dZ_{pred} = -mu Z_{pred} + b \cos(\omega Y_{pred}) ;
\end{cases}
$$

Merge results:

$$
\begin{align}
X = X + \dfrac{h}{2} (dX + dX_{pred});\\
Y = Y + \dfrac{h}{2} * (dY + dY_{pred});\\
Z = Z + \dfrac{h}{2} * (dZ + dZ_{pred}); 
\end{align}
$$

## System Architecture

<img width="1000" alt="schematic" src="https://github.com/user-attachments/assets/7b7992fe-da20-4775-bba8-af3a71a517fc" />

### Modules
1. **cos_chaos_top** (Top-level module)
   - Interfaces with board peripherals (LEDs, UART)
   - Manages system reset and user input via button

2. **cos_chaos** (Core chaotic system)
   - Implements the differential equation solver
   - Manages state machine for Runge-Kutta integration steps
   - Coordinates with the calculation core

3. **cos_chaos_core** (Calculation core)
   - Computes the right-hand part of differential equations
   - Instantiates the CORDIC cosine module
   - Performs all multiplications with proper fixed-point handling

4. **cos_cordic_q610** (CORDIC cosine calculator)
   - Calculates cosine values using CORDIC algorithm
   - Implements Q6.10 fixed-point format
  
5. **mult_shifted**
Fixed-point multiplier with proper scaling for fixed-point arithmetic: $c = a \dot b / 2^{fraction_length}$.

6. **mult_h_sum**
Combined multiply-and-add operation for integration steps in a single module.

## Implementation Details

Used Q6.10 format (16-bit total, 6 integer bits, 10 fractional bits). All calculations maintain this format for consistency.

Numerical integration is implemented in a 3-state machine:
1. State 0: Initial evaluation
2. State 1: Second evaluation at predicted state
3. State 2: Final update and output

## Tang Nano 20k Implementation

### Interfaces
- LED outputs for system status
- Button input for system control
- UART for data output in a format supported by serial monitor plotter (verified with plotter in Arduino IDE). Transferred $x$ variable is first scaled to 8-bit number, and then transferred as 3 digits via ``uart_tx.v`` module.

## Simulation
The testbench (`cos_chaos_top_tb.v`) includes:
- Clock generation (50 MHz)
- Reset sequence
- Button press simulation
- VCD waveform output for debugging.
This module also simulated UART transfer.

## Usage
1. Set initial conditions and parameters (X0, Y0, Z0, a, b, c, μ, ω, h)
2. Assert reset to initialize system
3. System runs autonomously after reset
4. Button press switches between signes of parameter $c$

## Testbench Files Overview

This project includes three comprehensive testbenches for verifying different components of the COS Chameleon system:

### cordic_q610_wave_tb.v
**Purpose**: Full verification of the CORDIC cosine/sine module across multiple waveform periods.

**Key Features**:
- Tests angles from -9π/2 to +9π/2 in Q6.10 fixed-point format
- Includes angle step of 0.1 (102 in Q6.10)
- Generates both cosine and sine outputs
- Outputs results to VCD file for waveform analysis
- Includes conversion functions between Q6.10 and real numbers

### cos_chaos_tb.v

**Purpose**:  Verifies full chaotic oscillator behavior with predefined parameters and initial conditions.

**System Configuration**:
```verilog
// Q6.10 Format Parameters
a = 2.5      // System parameter
b = 1.0      // Cosine amplitude  
c = -0.01    // Damping coefficient
μ = 1.0      // Dissipation factor
ω = 1.85     // Angular frequency
h = 0.05     // Integration step size

// Initial Conditions (Q6.10)
X₀ = 0.0     // Initial X state
Y₀ = 5.0     // Initial Y state 
Z₀ = 0.0     // Initial Z state
```
### cos_chaos_top_tb.v

**Purpose**: Test the overall performance, including chaotic dynamics generation, transferring data via UART and reaction to button presses.
