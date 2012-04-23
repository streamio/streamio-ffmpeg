Streamio FFMPEG
===============

Simple yet powerful wrapper around the ffmpeg command for reading metadata and transcoding movies.

All work on this project is sponsored by the online video platform [Streamio](http://streamio.com).

[![Streamio](http://d253c4ja9jigvu.cloudfront.net/assets/small-logo.png)](http://streamio.com)

Installation
------------

    (sudo) gem install streamio-ffmpeg

This version is tested against ffmpeg 0.10.2. So no guarantees with earlier (or much later) versions. Output and input standards have inconveniently changed rather a lot between versions of ffmpeg. My goal is to keep this library in sync with new versions of ffmpeg as they come along.

Usage
-----

### Require the gem

``` ruby
require 'rubygems'
require 'streamio-ffmpeg'
```

### Reading Metadata

``` ruby
movie = FFMPEG::Movie.new("path/to/movie.mov")

movie.duration # 7.5 (duration of the movie in seconds)
movie.bitrate # 481 (bitrate in kb/s)
movie.size # 455546 (filesize in bytes)

movie.video_stream # "h264, yuv420p, 640x480 [PAR 1:1 DAR 4:3], 371 kb/s, 16.75 fps, 15 tbr, 600 tbn, 1200 tbc" (raw video stream info)
movie.video_codec # "h264"
movie.colorspace # "yuv420p"
movie.resolution # "640x480"
movie.width # 640 (width of the movie in pixels)
movie.height # 480 (height of the movie in pixels)
movie.frame_rate # 16.72 (frames per second)

movie.audio_stream # "aac, 44100 Hz, stereo, s16, 75 kb/s" (raw audio stream info)
movie.audio_codec # "aac"
movie.audio_sample_rate # 44100
movie.audio_channels # 2

movie.valid? # true (would be false if ffmpeg fails to read the movie)
```

### Transcoding

First argument is the output file path.

``` ruby
movie.transcode("tmp/movie.mp4") # Default ffmpeg settings for mp4 format
```

Keep track of progress with an optional block.

``` ruby
movie.transcode("movie.mp4") { |progress| puts progress } # 0.2 ... 0.5 ... 1.0
```

Give custom command line options with a string.

``` ruby
movie.transcode("movie.mp4", "-ac aac -vc libx264 -ac 2 ...")
```

Use the EncodingOptions parser for humanly readable transcoding options. Below you'll find most of the supported options. Note that the :custom key will be used as is without modification so use it for any tricky business you might need.

``` ruby
options = {:video_codec => "libx264", :frame_rate => 10, :resolution => "320x240", :video_bitrate => 300, :video_bitrate_tolerance => 100,
           :croptop => 60, :cropbottom => 60, :cropleft => 10, :cropright => 10, :aspect => 1.333333, :keyframe_interval => 90,
           :audio_codec => "libfaac", :audio_bitrate => 32, :audio_sample_rate => 22050, :audio_channels => 1,
           :threads => 2,
           :custom => "-flags +loop -cmp +chroma -partitions +parti4x4+partp8x8 -flags2 +mixed_refs -me_method umh -subq 6 -refs 6 -rc_eq 'blurCplx^(1-qComp)' -coder 0 -me_range 16 -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qcomp 0.6 -qmin 10 -qmax 51 -qdiff 4 -level 21"}
movie.transcode("movie.mp4", options)
```

The transcode function returns a Movie object for the encoded file.

``` ruby
transcoded_movie = movie.transcode("tmp/movie.flv")

transcoded_movie.video_codec # "flv"
transcoded_movie.audio_codec # "mp3"
```

Aspect ratio is added to encoding options automatically if none is specified.

``` ruby
options = {:resolution => "320x180"} # Will add -aspect 1.77777777777778 to ffmpeg
```

Preserve aspect ratio on width or height by using the preserve_aspect_ratio transcoder option.

``` ruby
widescreen_movie = FFMPEG::Movie.new("path/to/widescreen_movie.mov")

options = {:resolution => "320x240"}

transcoder_options = {:preserve_aspect_ratio => :width}
widescreen_movie.transcode("movie.mp4", options, transcoder_options) # Output resolution will be 320x180

transcoder_options = {:preserve_aspect_ratio => :height}
widescreen_movie.transcode("movie.mp4", options, transcoder_options) # Output resolution will be 426x240
```

For constant bitrate encoding use video_min_bitrate and video_max_bitrate with buffer_size.

``` ruby
options = {:video_min_bitrate => 600, :video_max_bitrate => 600, :buffer_size => 2000}
movie.transcode("movie.flv", options)
```

Use ffpreset files to avoid headaches when encoding with libx264 (http://www.ffmpeg.org/ffmpeg-doc.html#SEC13).

``` ruby
options = {:video_codec => "libx264", :video_preset => "medium"} # audio_preset and file_preset also availible
movie.transcode("movie.mp4", options) # encodes video using libx264-medium.ffpreset
```
### Thumbnails

By default, the thumbnail will have the same resolution as the movie
If :safe options is set to false, will be almost instantaneous but may produce a grey screenshot

``` ruby
options = {:position => 222, :height=>100 , :width=> 200, :safe => true}
movie.thumbnail("/path/to/thumb.jpg",options)
```

Specify the path to ffmpeg
--------------------------

By default, streamio assumes that the ffmpeg binary is available in the execution path and named ffmpeg and so will run commands that look something like "ffmpeg -i /path/to/input.file ...". Use the FFMPEG.ffmpeg_binary setter to specify the full path to the binary if necessary:

``` ruby
FFMPEG.ffmpeg_binary = '/usr/local/bin/ffmpeg'
```

This will cause the same command to run as "/usr/local/bin/ffmpeg -i /path/to/input.file ..." instead.

Copyright
---------

Copyright (c) 2011 Streamio AB. See LICENSE for details.
