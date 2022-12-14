import math
import os

from stl import mesh

dir_path = os.path.dirname(os.path.realpath(__file__))
parent_dir_path = os.path.dirname(dir_path)
your_mesh = mesh.Mesh.from_file(
    f"{dir_path}/cube.stl"
)

new_shape = (your_mesh.points.shape[0], math.floor(your_mesh.points.shape[1] / 3), 3)

print(new_shape)


def float_to_hex(f):
    return f"{math.floor(f*4) & 0xFFFF:04x}"


def point_to_hex(color, x, y, z):
    # return f"{1:04x}{0x0001:04x}{0x0001:04x}{0x0001:04x}\n"
    return f"{color:1x}{float_to_hex(x)}{float_to_hex(y)}{float_to_hex(z)}\n"


def write_frame(f, c):
    for loop in your_mesh.points.reshape(*new_shape):
        for point in loop:
            f.write(point_to_hex(c, *point))
        f.write(point_to_hex(0, *loop[0]))


with open(f"{parent_dir_path}/data/image.mem", "w") as f:
    for c in range(0, 4):
        write_frame(f, c)
