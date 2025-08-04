# fpga_chaotic_chameleon_system
Verilog project of simple chaotic chameleon system implementation in FPGA. Contains a project for Tang Nano 20k board (IDE GoWin).

#### References

1. Xueqing Liu, ... Ning Wang (2025).
   "Simple Chaotic Chameleon System with Cosine Function".  
   *Journal*, *67*(5), 892-896. https://doi.org/xx.xxxx/TCSII.2020.xxxxxxx  

# COS Chameleon System in FPGA (Tang Nano 20k)

## Project Overview
This project implements a chaotic oscillator system on Tang Nano 20k FPGA board. The system models a set of differential equations that exhibit chaotic behavior, using fixed-point arithmetic and CORDIC-based cosine calculations.

## Key Features
- **Chaotic System Modeling**: Implements the chameleon chaotic oscillator system with three state variables (X, Y, Z)
- **Fixed-Point Arithmetic**: Uses 16-bit fixed-point numbers with 10 fractional bits for calculations
- **CORDIC Implementation**: Cosine calculation using 10-stage CORDIC algorithm and argument augmentation to the range [-9π/2, 9π/2]
- **Runge-Kutta Integration**: 2nd-order numerical integration (Heun method) for solving differential equation
- **FPGA-Optimized Design**: Calculation core controlled by state machine for efficient FPGA implementation

## System Architecture

### Main Modules
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
   - Optimized for Q6.10 fixed-point format

### Supporting Modules
- `mult_shifted`: Fixed-point multiplier with proper scaling
- `mult_h_sum`: Combined multiply-and-add operation for integration steps

## Differential Equations
The system implements the following chaotic equations:
...

Where:
- a, b, c, μ, ω are system parameters
- X, Y, Z are state variables
- cos(ωY) is calculated using CORDIC

## Implementation Details

### Fixed-Point Format
- Q6.10 format (16-bit total, 6 integer bits, 10 fractional bits)
- All calculations maintain this format for consistency

### Integration Method
- 2nd-order Runge-Kutta (RK2) method
- Two evaluation steps per integration:
  1. First evaluation at current state
  2. Second evaluation at predicted state
  3. Final update using averaged derivatives

### State Machine
The system uses a 3-state machine:
1. State 0: Initial evaluation
2. State 1: Second evaluation at predicted state
3. State 2: Final update and output

## Tang Nano 20k Implementation

### Resource Utilization
- Efficient use of FPGA resources:
  - DSP blocks for multiplications
  - LUTs for CORDIC implementation
  - Block RAM for state storage

### Interfaces
- LED outputs for system status
- UART for parameter configuration and data output
- Button input for system control

## Simulation
The testbench (`cos_chaos_top_tb.v`) includes:
- Clock generation (50 MHz)
- Reset sequence
- Button press simulation
- VCD waveform output for debugging

## Usage
1. Set initial conditions and parameters (X0, Y0, Z0, a, b, c, μ, ω, h)
2. Assert reset to initialize system
3. System runs autonomously after reset
4. Button presses can trigger specific actions (implementation-dependent)

## Future Enhancements
1. Real-time parameter adjustment via UART
2. Chaotic attractor visualization output
3. Higher-order integration methods
4. Adaptive step size control

# Testbench Documentation

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

**Test Parameters**:
```verilog
parameter CLK_PERIOD = 10;       // 10ns = 100MHz
parameter START_ANGLE = -9*16'sd1608; // -9π/2
parameter END_ANGLE = 9*16'sd1608;   // 9π/2
parameter STEP_ANGLE = 16'sd102;     // 0.1 increment
parameter PI_Q610 = 16'sd3217;       // π in Q6.10
```


### cos_sin_values_tb.v

**Purpose**:  
Validates the CORDIC cosine/sine generator at critical angular points across all four quadrants.

**Key Features**:
- Tests four representative angles:
  - `30°` (π/6, Quadrant I)
  - `120°` (2π/3, Quadrant II)  
  - `210°` (7π/6, Quadrant III)
  - `343°` (343π/180, Quadrant IV)
- Continuous operation mode with automatic angle sequencing
- Real-time output of both cosine and sine values
- Fixed-point Q6.10 format verification

**Test Methodology**:
1. Initializes with 2-clock cycle delay
2. Sequentially applies test angles on each `READY` signal
3. Maintains continuous operation for waveform analysis

**Outputs**:
- Generates `cos_sin_values.vcd` waveform file
- Console output for quick verification

---

### cos_chaos_optimized_tb.v

**Purpose**:  
Verifies full chaotic oscillator behavior with predefined parameters and initial conditions.

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
