use parking_lot::Mutex;
use rustler::{Atom, Binary, Env, NifResult, OwnedBinary, ResourceArc};

mod atoms {
    rustler::atoms! {
        ok,
    }
}

rustler::init!(
    "Elixir.MutableImage",
    [new, change_pixel, as_png],
    load = load
);

fn load(env: rustler::Env, _: rustler::Term) -> bool {
    rustler::resource!(MutableImage, env);
    true
}

#[rustler::nif]
fn new(width: u32, height: u32) -> (Atom, ResourceArc<MutableImage>) {
    let img = MutableImage::new(width, height);
    (atoms::ok(), ResourceArc::new(img))
}

#[derive(rustler::NifTuple)]
pub struct Coordinate {
    x: u32,
    y: u32,
}
#[derive(rustler::NifTuple)]
pub struct Color {
    r: u8,
    g: u8,
    b: u8,
}

#[rustler::nif]
fn change_pixel(
    mutable_image: ResourceArc<MutableImage>,
    coordinate: Coordinate,
    color: Color,
) -> NifResult<Atom> {
    mutable_image
        .change_pixel(
            coordinate.x,
            coordinate.y,
            image::Rgb::<u8>([color.r, color.g, color.b]),
        )
        .map_err(|t| rustler::Error::Term(Box::new(t)))?;
    Ok(atoms::ok())
}

#[rustler::nif]
fn as_png<'a>(
    env: Env<'a>,
    mutable_image: ResourceArc<MutableImage>,
) -> NifResult<(Atom, Binary<'a>)> {
    let mut binary =
        OwnedBinary::new(mutable_image.buffer_len()).expect("Failed to allocate new binary.");
    mutable_image
        .write_as_png(&mut binary.as_mut_slice())
        .map_err(|t| rustler::Error::Term(Box::new(t)))?;
    Ok((atoms::ok(), binary.release(env)))
}

struct MutableImage {
    width: u32,
    height: u32,
    // Using a Mutex instead of a RwLock because writes should be more frequent than reads.
    // TODO: Check the read/write ratio and evaluate if RwLock would be interesting.
    // TODO: Check if using Rc<> is ok since we never concurrently use the image.
    buffer: Mutex<image::RgbImage>,
    buffer_len: usize,
}

impl MutableImage {
    fn new(width: u32, height: u32) -> Self {
        let buffer = image::RgbImage::new(width, height);
        Self {
            width: width,
            height: height,
            buffer_len: buffer.len(),
            buffer: Mutex::new(buffer),
        }
    }

    fn buffer_len(&self) -> usize {
        self.buffer_len
    }

    fn change_pixel(&self, x: u32, y: u32, pixel: image::Rgb<u8>) -> Result<(), &'static str> {
        if x >= self.width || y >= self.height {
            return Err("out_of_bounds");
        }
        self.buffer
            .try_lock()
            .ok_or("invalid_concurrent_use")?
            .put_pixel(x, y, pixel);
        Ok(())
    }

    fn write_as_png<W: std::io::Write>(&self, output_buffer: &mut W) -> Result<(), &'static str> {
        let buffer = self.buffer.try_lock().ok_or("invalid_concurrent_use")?;

        let png_encoder = image::codecs::png::PngEncoder::new(output_buffer);
        png_encoder
            .encode(&buffer, self.width, self.height, image::ColorType::Rgb8)
            .expect("Failed to encode image");
        Ok(())
    }
}
