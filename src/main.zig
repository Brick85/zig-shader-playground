const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const glfw_log = std.log.scoped(.glfw);
const gl_log = std.log.scoped(.gl);

fn logGLFWError(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    glfw_log.err("{}: {s}\n", .{ error_code, description });
}

var gl_procs: gl.ProcTable = undefined;

/// ```txt
/// square:
/// (3)                  (2)
///     -----------------
///     |\              |
///     |  \            |
///     |    \          |
///     |       \       |
///     |          \    |
///     |             \ |
///     -----------------
/// (0)                  (1)
/// ```
///
const qmesh = struct {
    // zig fmt: off
    const vertices = [_]Vertex{
        .{ .position = .{ -1, -1 }, .color = .{ 1, 0, 0 } },
        .{ .position = .{  1, -1 }, .color = .{ 0, 1, 0 } },
        .{ .position = .{  1,  1 }, .color = .{ 0, 0, 1 } },
        .{ .position = .{ -1,  1 }, .color = .{ 1, 1, 1 } },
    };
    // zig fmt: on

    const indices = [_]u8{
        0, 1, 3,
        3, 1, 2,
    };

    const Vertex = extern struct {
        position: Position,
        color: Color,

        const Position = [2]f32;
        const Color = [3]f32;
    };
};

pub fn main() !void {
    glfw.setErrorCallback(logGLFWError);

    if (!glfw.init(.{})) {
        glfw_log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        return error.GLFWInitFailed;
    }
    defer glfw.terminate();

    // Create our window, specifying that we want to use OpenGL.
    const window = glfw.Window.create(640, 480, "mach-glfw + OpenGL", null, null, .{
        .context_version_major = gl.info.version_major,
        .context_version_minor = gl.info.version_minor,
        .opengl_profile = .opengl_core_profile,
        .opengl_forward_compat = true,
    }) orelse {
        glfw_log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        return error.CreateWindowFailed;
    };
    defer window.destroy();

    // Make the window's OpenGL context current.
    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    // Enable VSync to avoid drawing more often than necessary.
    glfw.swapInterval(1);

    // Initialize the OpenGL procedure table.
    if (!gl_procs.init(glfw.getProcAddress)) {
        gl_log.err("failed to load OpenGL functions", .{});
        return error.GLInitFailed;
    }

    var vertex_shader: c_uint = undefined;
    var fragment_shader: c_uint = undefined;
    // Make the OpenGL procedure table current.
    gl.makeProcTableCurrent(&gl_procs);
    defer gl.makeProcTableCurrent(null);

    const program = create_program: {
        var success: c_int = undefined;
        var info_log_buf: [512:0]u8 = undefined;

        const program = gl.CreateProgram();
        if (program == 0) return error.CreateProgramFailed;
        errdefer gl.DeleteProgram(program);

        vertex_shader = createVertexShader(program) catch {
            return error.CreateShadersFailed;
        };

        fragment_shader = createFragmentShader(program) catch {
            return error.CreateShadersFailed;
        };

        gl.LinkProgram(program);
        gl.GetProgramiv(program, gl.LINK_STATUS, &success);
        if (success == gl.FALSE) {
            gl.GetProgramInfoLog(program, info_log_buf.len, null, &info_log_buf);
            gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
            return error.LinkProgramFailed;
        }

        break :create_program program;
    };

    defer gl.DeleteProgram(program);

    const framebuffer_size_uniform = gl.GetUniformLocation(program, "u_FramebufferSize");
    const time_uniform = gl.GetUniformLocation(program, "u_Time");

    // Vertex Array Object (VAO), remembers instructions for how vertex data is laid out in memory.
    // Using VAOs is strictly required in modern OpenGL.
    var vao: c_uint = undefined;
    gl.GenVertexArrays(1, (&vao)[0..1]);
    defer gl.DeleteVertexArrays(1, (&vao)[0..1]);

    // Vertex Buffer Object (VBO), holds vertex data.
    var vbo: c_uint = undefined;
    gl.GenBuffers(1, (&vbo)[0..1]);
    defer gl.DeleteBuffers(1, (&vbo)[0..1]);

    // Index Buffer Object (IBO), maps indices to vertices (to enable reusing vertices).
    var ibo: c_uint = undefined;
    gl.GenBuffers(1, (&ibo)[0..1]);
    defer gl.DeleteBuffers(1, (&ibo)[0..1]);

    {
        // Make our VAO the current global VAO, but unbind it when we're done so we don't end up
        // inadvertently modifying it later.
        gl.BindVertexArray(vao);
        defer gl.BindVertexArray(0);

        {
            // Make our VBO the current global VBO and unbind it when we're done.
            gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
            defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

            // Upload vertex data to the VBO.
            gl.BufferData(
                gl.ARRAY_BUFFER,
                @sizeOf(@TypeOf(qmesh.vertices)),
                &qmesh.vertices,
                gl.STATIC_DRAW,
            );

            // Instruct the VAO how vertex position data is laid out in memory.
            const position_attrib: c_uint = @intCast(gl.GetAttribLocation(program, "a_Position"));
            gl.EnableVertexAttribArray(position_attrib);
            gl.VertexAttribPointer(
                position_attrib,
                @typeInfo(qmesh.Vertex.Position).Array.len,
                gl.FLOAT,
                gl.FALSE,
                @sizeOf(qmesh.Vertex),
                @offsetOf(qmesh.Vertex, "position"),
            );

            // Ditto for vertex colors.
            const color_attrib: c_uint = @intCast(gl.GetAttribLocation(program, "a_Color"));
            gl.EnableVertexAttribArray(color_attrib);
            gl.VertexAttribPointer(
                color_attrib,
                @typeInfo(qmesh.Vertex.Color).Array.len,
                gl.FLOAT,
                gl.FALSE,
                @sizeOf(qmesh.Vertex),
                @offsetOf(qmesh.Vertex, "color"),
            );
        }

        // Instruct the VAO to use our IBO, then upload index data to the IBO.
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo);
        gl.BufferData(
            gl.ELEMENT_ARRAY_BUFFER,
            @sizeOf(@TypeOf(qmesh.indices)),
            &qmesh.indices,
            gl.STATIC_DRAW,
        );
    }

    var timer = try std.time.Timer.start();

    var i: u16 = 0;
    const shader_dir = try std.fs.cwd().openDir("shaders", .{ .iterate = true });

    var last_inode_frag: u64 = 0;
    var last_inode_vert: u64 = 0;

    main_loop: while (true) {
        glfw.pollEvents();

        // Exit the main loop if the user is trying to close the window.
        if (window.shouldClose()) break :main_loop;

        {
            if (i == 0) {
                // TODO recompiles at first run. Not important, can be left as is.
                // TODO runs depending on frame rate. Probably need to be fixed.
                const stat_frag = try shader_dir.statFile("fragment.glsl");
                if (stat_frag.inode != last_inode_frag) {
                    last_inode_frag = stat_frag.inode;
                    std.debug.print("recompiling fragment shader\n", .{});
                    const ok = compileShader(fragment_shader, "shaders/fragment.glsl") catch false;
                    if (ok) gl.LinkProgram(program);
                }
                const stat_vert = try shader_dir.statFile("vertex.glsl");
                if (stat_vert.inode != last_inode_vert) {
                    last_inode_vert = stat_vert.inode;
                    std.debug.print("recompiling vertex shader\n", .{});
                    const ok = compileShader(vertex_shader, "shaders/vertex.glsl") catch false;
                    if (ok) gl.LinkProgram(program);
                }
            }
            i = i + 1;
            if (i == 200) {
                i = 0;
            }

            // Clear the screen to white.
            gl.ClearColor(1, 1, 1, 1);
            gl.Clear(gl.COLOR_BUFFER_BIT);

            gl.UseProgram(program);
            defer gl.UseProgram(0);

            // Make sure any changes to the window's size are reflected.
            const framebuffer_size = window.getFramebufferSize();
            gl.Viewport(0, 0, @intCast(framebuffer_size.width), @intCast(framebuffer_size.height));
            gl.Uniform2f(framebuffer_size_uniform, @floatFromInt(framebuffer_size.width), @floatFromInt(framebuffer_size.height));

            // Pass the current run time to the shader.
            const seconds = @as(f32, @floatFromInt(timer.read())) / std.time.ns_per_s;
            gl.Uniform1f(time_uniform, seconds);

            gl.BindVertexArray(vao);
            defer gl.BindVertexArray(0);

            // Draw the mesh!
            gl.DrawElements(gl.TRIANGLES, qmesh.indices.len, gl.UNSIGNED_BYTE, 0);
        }

        window.swapBuffers();
    }
}

fn compileShader(shader: c_uint, filename: []const u8) !bool {
    var success: c_int = undefined;
    var info_log_buf: [512:0]u8 = undefined;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const shader_source = try std.fs.cwd().readFileAlloc(gpa.allocator(), filename, std.math.maxInt(usize));
    gl.ShaderSource(
        shader,
        1,
        (&shader_source.ptr)[0..1],
        (&@as(c_int, @intCast(shader_source.len)))[0..1],
    );
    gl.CompileShader(shader);
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success);
    if (success == gl.FALSE) {
        gl.GetShaderInfoLog(shader, info_log_buf.len, null, &info_log_buf);
        gl_log.err("{s}", .{std.mem.sliceTo(&info_log_buf, 0)});
        return error.CompileShaderFailed;
    }
    return true;
}

fn createVertexShader(program: c_uint) !c_uint {
    const vertex_shader_filename = "./shaders/init_vertex.glsl";
    const vertex_shader = gl.CreateShader(gl.VERTEX_SHADER);
    if (vertex_shader == 0) return error.CreateVertexShaderFailed;
    defer gl.DeleteShader(vertex_shader);
    const ok = compileShader(vertex_shader, vertex_shader_filename) catch {
        return error.CompileShaderFailed;
    };
    if (ok) gl.AttachShader(program, vertex_shader);
    return vertex_shader;
}

fn createFragmentShader(program: c_uint) !c_uint {
    const fragment_shader_filename = "./shaders/init_fragment.glsl";
    const fragment_shader = gl.CreateShader(gl.FRAGMENT_SHADER);
    if (fragment_shader == 0) return error.CreateFragmentShaderFailed;
    defer gl.DeleteShader(fragment_shader);
    const ok = compileShader(fragment_shader, fragment_shader_filename) catch {
        return error.CompileShaderFailed;
    };
    if (ok) gl.AttachShader(program, fragment_shader);
    return fragment_shader;
}
