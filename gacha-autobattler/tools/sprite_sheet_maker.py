#!/usr/bin/env python3
"""
Sprite Sheet Maker
Extracts frames from video/GIF and assembles them into sprite sheets.

Usage:
    python sprite_sheet_maker.py input.mp4 output.png --frames 3
    python sprite_sheet_maker.py input.gif output.png --frames 3 --size 128
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow not installed. Run: pip install Pillow")
    sys.exit(1)

try:
    import cv2
except ImportError:
    cv2 = None
    print("WARNING: OpenCV not installed. Video support disabled. Run: pip install opencv-python")


def extract_frames_from_gif(gif_path: Path, num_frames: int) -> list[Image.Image]:
    """Extract evenly spaced frames from a GIF."""
    gif = Image.open(gif_path)

    # Count total frames
    total_frames = 0
    try:
        while True:
            total_frames += 1
            gif.seek(gif.tell() + 1)
    except EOFError:
        pass

    # Calculate which frames to extract (evenly spaced)
    if total_frames <= num_frames:
        frame_indices = list(range(total_frames))
    else:
        step = total_frames / num_frames
        frame_indices = [int(i * step) for i in range(num_frames)]

    # Extract frames
    frames = []
    gif.seek(0)
    for i in range(total_frames):
        if i in frame_indices:
            # Convert to RGBA to preserve transparency
            frame = gif.convert("RGBA")
            frames.append(frame.copy())
        try:
            gif.seek(gif.tell() + 1)
        except EOFError:
            break

    return frames


def extract_frames_from_video(video_path: Path, num_frames: int) -> list[Image.Image]:
    """Extract evenly spaced frames from a video file."""
    if cv2 is None:
        print("ERROR: OpenCV required for video files. Run: pip install opencv-python")
        sys.exit(1)

    cap = cv2.VideoCapture(str(video_path))
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    if total_frames <= 0:
        print(f"ERROR: Could not read video: {video_path}")
        sys.exit(1)

    # Calculate which frames to extract
    if total_frames <= num_frames:
        frame_indices = list(range(total_frames))
    else:
        step = total_frames / num_frames
        frame_indices = [int(i * step) for i in range(num_frames)]

    frames = []
    for idx in frame_indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
        ret, frame = cap.read()
        if ret:
            # Convert BGR to RGB
            frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            img = Image.fromarray(frame_rgb).convert("RGBA")
            frames.append(img)

    cap.release()
    return frames


def remove_background(img: Image.Image, bg_color: tuple = (255, 255, 255), tolerance: int = 30) -> Image.Image:
    """Make background color transparent."""
    img = img.convert("RGBA")
    data = img.getdata()

    new_data = []
    for item in data:
        # Check if pixel is close to background color
        if (abs(item[0] - bg_color[0]) < tolerance and
            abs(item[1] - bg_color[1]) < tolerance and
            abs(item[2] - bg_color[2]) < tolerance):
            new_data.append((255, 255, 255, 0))  # Transparent
        else:
            new_data.append(item)

    img.putdata(new_data)
    return img


def create_sprite_sheet(frames: list[Image.Image], frame_size: int, horizontal: bool = True) -> Image.Image:
    """Combine frames into a sprite sheet."""
    num_frames = len(frames)

    # Resize frames
    resized = []
    for frame in frames:
        # Maintain aspect ratio, fit within frame_size
        frame.thumbnail((frame_size, frame_size), Image.Resampling.LANCZOS)

        # Create square canvas and center the frame
        canvas = Image.new("RGBA", (frame_size, frame_size), (0, 0, 0, 0))
        x = (frame_size - frame.width) // 2
        y = (frame_size - frame.height) // 2
        canvas.paste(frame, (x, y), frame if frame.mode == "RGBA" else None)
        resized.append(canvas)

    # Create sprite sheet
    if horizontal:
        sheet = Image.new("RGBA", (frame_size * num_frames, frame_size), (0, 0, 0, 0))
        for i, frame in enumerate(resized):
            sheet.paste(frame, (i * frame_size, 0))
    else:
        sheet = Image.new("RGBA", (frame_size, frame_size * num_frames), (0, 0, 0, 0))
        for i, frame in enumerate(resized):
            sheet.paste(frame, (0, i * frame_size))

    return sheet


def main():
    parser = argparse.ArgumentParser(description="Create sprite sheets from video/GIF")
    parser.add_argument("input", help="Input video or GIF file")
    parser.add_argument("output", help="Output sprite sheet PNG")
    parser.add_argument("--frames", "-f", type=int, default=3, help="Number of frames to extract (default: 3)")
    parser.add_argument("--size", "-s", type=int, default=128, help="Frame size in pixels (default: 128)")
    parser.add_argument("--remove-bg", "-r", action="store_true", help="Remove white background")
    parser.add_argument("--tolerance", "-t", type=int, default=30, help="Background removal tolerance (default: 30)")
    parser.add_argument("--vertical", "-v", action="store_true", help="Stack frames vertically instead of horizontally")
    parser.add_argument("--preview", "-p", action="store_true", help="Save individual frames as well")

    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.exists():
        print(f"ERROR: Input file not found: {input_path}")
        sys.exit(1)

    # Determine input type and extract frames
    suffix = input_path.suffix.lower()
    print(f"Processing: {input_path}")

    if suffix == ".gif":
        frames = extract_frames_from_gif(input_path, args.frames)
    elif suffix in [".mp4", ".avi", ".mov", ".webm", ".mkv"]:
        frames = extract_frames_from_video(input_path, args.frames)
    else:
        print(f"ERROR: Unsupported format: {suffix}")
        print("Supported: .gif, .mp4, .avi, .mov, .webm, .mkv")
        sys.exit(1)

    print(f"Extracted {len(frames)} frames")

    # Remove background if requested
    if args.remove_bg:
        print("Removing white background...")
        frames = [remove_background(f, tolerance=args.tolerance) for f in frames]

    # Save individual frames if preview requested
    if args.preview:
        preview_dir = output_path.parent / f"{output_path.stem}_frames"
        preview_dir.mkdir(exist_ok=True)
        for i, frame in enumerate(frames):
            frame_resized = frame.copy()
            frame_resized.thumbnail((args.size, args.size), Image.Resampling.LANCZOS)
            frame_resized.save(preview_dir / f"frame_{i:02d}.png")
        print(f"Saved individual frames to: {preview_dir}")

    # Create and save sprite sheet
    sheet = create_sprite_sheet(frames, args.size, horizontal=not args.vertical)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path)

    print(f"Sprite sheet saved: {output_path}")
    print(f"Dimensions: {sheet.width}x{sheet.height} ({len(frames)} frames @ {args.size}x{args.size})")


if __name__ == "__main__":
    main()
