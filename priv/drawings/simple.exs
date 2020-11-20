
Enum.reduce(0..10, fn t, _acc -> PixelForum.Images.ImageServer.change_pixel(0, {t, 50}, {255, 0, 0}) end)

Enum.reduce(0..10000, fn t, _acc ->
  PixelForum.Images.ImageServer.change_pixel(0, {rem(floor(50 + t * 3 + t / 500), 512), rem(floor(25 + t / 2 + t / 255), 512)}, {rem(t, 255), 255, 255})
end)

Enum.reduce(0..10000, fn _t, _acc -> PixelForum.Images.ImageServer.change_pixel(0, {:rand.uniform(512), :rand.uniform(512)}, {0, 0, 255}) end)

Enum.reduce(0..10000, fn t, _acc -> PixelForum.Images.ImageServer.change_pixel(0, {rem(t + :rand.uniform(10), 512), rem(200 + t/300, 512)}, {0, 0, 255}) end)

Enum.reduce(0..10000, fn t, _acc -> PixelForum.Images.ImageServer.change_pixel(0, {rem(200 + :rand.uniform(30), 512), rem(floor(200 + t / 300), 512)}, {0, 255, 0}) end)

Enum.reduce(0..100000, fn t, _acc -> PixelForum.Images.ImageServer.change_pixel(0, {rem(floor(200 + :rand.uniform(30) + t*9), 512), rem(floor(200 + t*2), 512)}, {250, rem(floor(2*t), 255), 0}) end)

:rand.uniform(n)
rand.uniform(255)

lobby_id = "1f12b09f-21e5-4d7e-bc7e-cb8d75dc3ce2"

spawn(fn -> Enum.reduce(0..100000, fn t, _acc -> PixelForum.Images.ImageServer.change_pixel(lobby_id, 0, {rem(floor(200 + :rand.uniform(30) + t*9), 512), rem(floor(200 + t*2 + :rand.uniform(2)), 512)}, {250, rem(floor(2*t), 255), 0}) end) end)
