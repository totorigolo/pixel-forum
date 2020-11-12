
Enum.reduce(0..10000, fn x, _acc ->
  PixelForum.Images.Image.change_pixel({rem(floor(50 + x * 3 + x / 500), 512), rem(floor(25 + x / 2 + x / 255), 512)}, {rem(x, 255), 255, 255})
end)

Enum.reduce(0..10000, fn _x, _acc -> PixelForum.Images.Image.change_pixel({:rand.uniform(512), :rand.uniform(512)}, {0, 0, 255}) end)

Enum.reduce(0..10000, fn x, _acc -> PixelForum.Images.Image.change_pixel({rem(x + :rand.uniform(10), 512), rem(200 + x/300, 512)}, {0, 0, 255}) end)

Enum.reduce(0..10000, fn x, _acc -> PixelForum.Images.Image.change_pixel({rem(200 + :rand.uniform(30), 512), rem(floor(200 + x / 300), 512)}, {0, 255, 0}) end)

Enum.reduce(0..100000, fn x, _acc -> PixelForum.Images.Image.change_pixel({rem(floor(200 + :rand.uniform(30) + x*9), 512), rem(floor(200 + x*2), 512)}, {250, rem(floor(2*x), 255), 0}) end)

:rand.uniform(n)
rand.uniform(255)
