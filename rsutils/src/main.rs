use snesgfx::from;
use image::imageops;
use std::error::Error;

fn main() {
    let mut args = std::env::args();
    args.next();
    let res = match &*args.next().unwrap() {
        "mappings" => mappings(args),
        "chunks" => chunks(args),
        _ => Err("tf".to_string().into())
    };
    if let Err(e) = res {
        println!("Error: {}", e);
    }
}

fn chunks(mut args: impl Iterator<Item=String>) -> Result<(),Box<Error>> {
    use std::collections::HashMap;
    use std::fmt::Write;
    let mut next = || args.next().ok_or_else(arg_error);
    let tiles = tiled::Map::read(&next()?)?;
    let tl = if let tiled::LayerKind::TileLayer(t) = &tiles.layers[0] { t } else { return Err("layer 1 not a tile layer".to_string().into()) };
    let mut chunks = HashMap::new();
    for cy in (0..tl.height).step_by(32) {
        for cx in (0..tl.width).step_by(32) {
            let chunk = (0..32)
                .flat_map(|c| (0..32).map(move |i| (cx+i,cy+c)))
                .map(|(x,y)| tl.data[(x+y*tl.width) as usize])
                .map(|d| (d.saturating_sub(1)) as u8)
                .collect::<Vec<_>>();
            chunks.insert((cx,cy), chunk);
        }
    }
    let mut out = "#[bank(05)]\n".to_string();
    for ((x,y),v) in chunks.iter() {
        let x = *x; let y = *y;
        write!(out, "Chunk_{:04X}_{:04X}:\n", x, y);
        let d = |x,y| {
            if chunks.get(&(x,y)).is_some() {
                format!("Chunk_{:04X}_{:04X}", x, y)
            } else {
                "$FFFFFF".to_string()
            }
        };
        write!(out, "dl BlockMappings, BlockMappings, {}, {}, {}, {}\ndb ", d(x,y.wrapping_sub(32)), d(x,y+32), d(x.wrapping_sub(32),y), d(x+32,y))?;
        // uncompressed for now
        for i in v {
            write!(out, "${:02X},", i)?;
        }
        out.pop();
        write!(out, "\n")?;
    }
    std::fs::write("chunks.asm", &out)?;
    Ok(())
}

fn mappings(mut args: impl Iterator<Item=String>) -> Result<(),Box<Error>> {
    use snesgfx::from::TilemapCell;
    use std::fs::File;
    use std::io::Write;
    let mut next = || args.next().ok_or_else(arg_error);
    let mappings = tiled::Map::read(&next()?)?;
    let palette = from::Palette::from_slice(&std::fs::read(&next()?)?);
    let tileset = from::Tileset::from_bitplane(4, &std::fs::read(&next()?)?);
    let mut tiles = [vec![],vec![],vec![],vec![]];
    let mut out = image::ImageBuffer::new(128, 256);
    // T tcccttt
    fn conv(i: u32) -> u16 {
        if i == 0 { return 0xFF }
        let hflip = i & (1 << 31) != 0;
        let vflip = i & (1 << 30) != 0;
        //let dflip = i & (1 << 29) != 0;
        let tid = (i & !0xE0000000) - 1;
        let id_low = tid & 0b1111;
        let id_pal = (tid & 0b1110000) >> 4;
        let id_high = (tid & 0x3F80) >> 3;
        (vflip as u16 * 0x8000)
        | (hflip as u16 * 0x4000)
        | ((id_pal as u16) << 10)
        | (id_high as u16)
        | (id_low as u16)
    }
    let tl = if let tiled::LayerKind::TileLayer(t) = &mappings.layers[0] { t } else { return Err("layer 1 not a tile layer".to_string().into()) };
    for y in 0u32..tl.data.len() as u32/32 {
        for x in 0u32..8 {
            let pos = (x*2+y*32) as usize;
            let t = conv(tl.data[pos]);
            let img = TilemapCell(t).render_with(&tileset, &palette).unwrap();
            imageops::overlay(&mut out, &img, x*16, y*16);
            tiles[0].push(t as u8);
            tiles[0].push((t>>8) as u8);
            let t = conv(tl.data[pos+1]);
            let img = TilemapCell(t).render_with(&tileset, &palette).unwrap();
            imageops::overlay(&mut out, &img, x*16+8, y*16);
            tiles[1].push(t as u8);
            tiles[1].push((t>>8) as u8);
            let t = conv(tl.data[pos+16]);
            let img = TilemapCell(t).render_with(&tileset, &palette).unwrap();
            imageops::overlay(&mut out, &img, x*16, y*16+8);
            tiles[2].push(t as u8);
            tiles[2].push((t>>8) as u8);
            let t = conv(tl.data[pos+17]);
            let img = TilemapCell(t).render_with(&tileset, &palette).unwrap();
            imageops::overlay(&mut out, &img, x*16+8, y*16+8);
            tiles[3].push(t as u8);
            tiles[3].push((t>>8) as u8);
        }
    }
    let mut file = File::create("mappings.bin")?;
    tiles.iter().map(|c| file.write(&c).map(|_|())).collect::<Result<(),_>>()?;
    out.save("mappings_rendered.png")?;
    Ok(())
}


fn arg_error() -> String {
    "not enough args buddy".to_string()
}
