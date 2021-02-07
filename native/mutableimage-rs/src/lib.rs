use parking_lot::Mutex;
use rustler::{Atom, Binary, Env, NifResult, OwnedBinary, ResourceArc};

mod atoms {
    rustler::atoms! {
        ok,
        out_of_bounds,
        invalid_concurrent_use,
    }
}

rustler::init!(
    "Elixir.MutableImage",
    [new, get_pixel, change_pixel, as_png],
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

impl From<image::Rgb<u8>> for Color {
    fn from(rgb: image::Rgb<u8>) -> Self {
        Color {
            r: rgb[0],
            g: rgb[1],
            b: rgb[2],
        }
    }
}

#[rustler::nif]
fn get_pixel(
    mutable_image: ResourceArc<MutableImage>,
    coordinate: Coordinate,
) -> NifResult<(Atom, Color)> {
    let pixel = mutable_image
        .get_pixel(coordinate.x, coordinate.y)
        .map_err(|t| rustler::Error::Term(Box::new(t)))?;
    Ok((atoms::ok(), pixel.into()))
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

    fn get_pixel(&self, x: u32, y: u32) -> Result<image::Rgb<u8>, rustler::Atom> {
        if x >= self.width || y >= self.height {
            return Err(atoms::out_of_bounds());
        }
        let color = *self
            .buffer
            .try_lock()
            .ok_or(atoms::invalid_concurrent_use())?
            .get_pixel(x, y);
        Ok(color)
    }

    fn change_pixel(&self, x: u32, y: u32, pixel: image::Rgb<u8>) -> Result<(), rustler::Atom> {
        if x >= self.width || y >= self.height {
            return Err(atoms::out_of_bounds());
        }
        self.buffer
            .try_lock()
            .ok_or(atoms::invalid_concurrent_use())?
            .put_pixel(x, y, pixel);
        Ok(())
    }

    fn write_as_png<W: std::io::Write>(&self, output_buffer: &mut W) -> Result<(), rustler::Atom> {
        let buffer = self
            .buffer
            .try_lock()
            .ok_or(atoms::invalid_concurrent_use())?;

        let png_encoder = image::codecs::png::PngEncoder::new(output_buffer);
        png_encoder
            .encode(&buffer, self.width, self.height, image::ColorType::Rgb8)
            .expect("Failed to encode image");
        Ok(())
    }
}
