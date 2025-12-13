#!/bin/bash
SOURCE="omniluck_icon_master.png"
DEST="Assets.xcassets/AppIcon.appiconset"

# Ensure destination exists
mkdir -p "$DEST"

echo "Generating Icons from $SOURCE to $DEST..."

# Function to resize using sips (macOS native tool)
resize() {
    NAME=$1
    SIZE=$2
    # Use -Z to preserve aspect ratio (though icon is square), ensuring int output
    sips -z $SIZE $SIZE "$SOURCE" --out "$DEST/$NAME" || echo "ERROR: Failed to generate $NAME"
}

# iPhone
resize "Icon-20@2x.png" 40
resize "Icon-20@3x.png" 60
resize "Icon-29@2x.png" 58
resize "Icon-29@3x.png" 87
resize "Icon-40@2x.png" 80
resize "Icon-40@3x.png" 120
resize "Icon-60@2x.png" 120
resize "Icon-60@3x.png" 180

# iPad
resize "Icon-76.png" 76
resize "Icon-76@2x.png" 152
resize "Icon-83.5@2x.png" 167

# iPad Pro / Marketing - Use CP for max quality master
cp "$SOURCE" "$DEST/Icon-1024.png"

# Verify all files exist
for file in "Icon-20@2x.png" "Icon-20@3x.png" "Icon-29@2x.png" "Icon-29@3x.png" "Icon-40@2x.png" "Icon-40@3x.png" "Icon-60@2x.png" "Icon-60@3x.png" "Icon-76.png" "Icon-76@2x.png" "Icon-83.5@2x.png" "Icon-1024.png"; do
    if [ ! -f "$DEST/$file" ]; then
        echo "MISSING: $file"
    else
        echo "OK: $file"
    fi
done

echo "Creating Contents.json..."
# Create Contents.json
cat > "$DEST/Contents.json" <<EOF
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-40@2x.png",
      "scale" : "2x"
    },
    {
       "size" : "76x76",
       "idiom" : "ipad",
       "filename" : "Icon-76.png",
       "scale" : "1x"
    },
    {
       "size" : "76x76",
       "idiom" : "ipad",
       "filename" : "Icon-76@2x.png",
       "scale" : "2x"
    },
    {
       "size" : "83.5x83.5",
       "idiom" : "ipad",
       "filename" : "Icon-83.5@2x.png",
       "scale" : "2x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "Icon-1024.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF

echo "Icons generated successfully in $DEST"
