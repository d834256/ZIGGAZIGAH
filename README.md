# ZIGGAZIGAH
## Cut ups for the video age.

Very alpha. Use at your own risk.

### What is this?

This is a couple of bash scripts used to generate a single .mp4 file which is a seemingly random series of clips sourced from media that you provide.

### Why on earth would anyone want this?

I go into a lengthier explaination in the devdiary but basically my interest is music performance. Bands of certain genres often use back projections during their performances to show something visually interesting while the performer is standing behind a laptop twiddling knobs.

There are other use cases of course, but this is my use case and I stand by this.

### Requirements

Off the top of my head.

```
sqlite
ffmpeg
ffprobe
```

I tested this script on CentOS 7, but I tried to make it generic enough to run anywhere. One of the reasons why it's not in Perl or Python.

There was some stuff in the docs for ffmpeg's handling of burning in subtitles that suggested it needs to be compiled with certain options. I think I grabbed a pre-built binary from ffmpeg rather than using the CentOS packaged versions so if your subtitles aren't appearing this is probably why.

I've added ffprobe to this list recently. It's available from the same place as ffmpeg. 

### How to get started

Fair warning, this script is very alpha. Most of the working files use cwd, or ./tmp (note the ./) to store files.

First off create a text file. On each line of the file you can place either a directory or a full path to a media file. It doesn't matter.

mymovies.txt :

```
/home/fred/movies/
/nas/tv/eastenders/s120e01.mp4
```

What does matter is that you need to have a corresponding .srt file for any media that you specify. The script will expect that the .srt will have the same filename as your video, just with .srt as the extension rather than .mp4 or .avi etc.

Once you've done that, you need to ingest the .srt files into a sqlite database.

You do this like so :

```
./ingest_words.sh mymovies.txt
```

What you should see next is some scrolling text indicating that the script is going through the .srt files it has found line by line and inserting the data into the sqlite database. This can take some time depending on how much media you are ingesting.

Once that is complete, the script will exit. Next up you want to choose how you want to generate your video of randomness.

You have two options here.

```
./make_video.sh keywords "Leeds fragment boatyard iodine moon imagine shots dragon lunar"
```

This will search the database for keywords. It'll then use the timecodes to extract that section of video from the associated video file. If the keyword matches more than once the script will randomly choose one of the occurances for you.

The second, and maybe more interesting mode, is purely random. You just tell it how many lines of random dialogue you want.

```
./make_video.sh random 23
```

### A word about the length of the video clips

There's a variable called TOLERANCE in the make_video.sh which determines how many frames either side of the chosen point in time the script will extract. This is to stop the video content strobing you into a seizure. If however you like to live dangerously you can change that TOLERANCE value which should give the audio a more constant disjointed feel.

### How do I get rid of the subtitles in the movie clips?

You can edit the make_video.sh script and change the SUBTTILES variable to 0 to turn that off.

### Why does this script not download subtitles for me?

There are already 101 projects on github that will do this for you and quite honestly I don't have time to look into the legality of doing so.
