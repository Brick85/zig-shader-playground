# Zig Shader Playground

A local shader playground inspired by [Shadertoy](https://shadertoy.com), built with Zig and OpenGL. This tool enables real-time shader development, providing automatic compilation and live reloading of shaders upon saving changes—ideal for experimenting and iterating with shader code.

## Features

- **Instant Feedback:** Auto-compiles and auto-reloads shaders as you save them.
- **Local Setup:** All shader editing and previewing is done locally, so no internet connection is required.

## Getting Started

### Prerequisites

This project requires a compatible Zig compiler version to run. Use the following Zig version, as compatibility may vary:

- **Zig Version**: `zigup 0.12.0-dev.3180+83e578a18` / `2024.3.0-mach`

You can follow the installation instructions in [Nominated Zig versions](https://machengine.org/about/nominated-zig/#202430-mach) to install the correct compiler version for this project.

### Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/Brick85/zig-shader-playground.git
   cd zig-shader-playground
   ```

2. **Build and run the Project**
   Run the following Zig build command in the project directory:

   ```bash

   zig build run
   ```

### Usage

- Open any shader file in the project directory in your preferred code editor.

- Make changes to the shader code and save the file. The playground will automatically compile and reload the shader to reflect the changes in real-time.

## Credits

This project builds upon the initial code from [`mach-glfw-opengl-example`](https://github.com/slimsag/mach-glfw-opengl-example).

## Contributing

Contributions are welcome! Feel free to submit issues or open pull requests for new features, improvements, or bug fixes.

1. **Fork the repository**
2. **Create a new branch** for your feature or bug fix.
3. **Commit your changes** with clear messages.
4. **Open a pull request** to this repository.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
