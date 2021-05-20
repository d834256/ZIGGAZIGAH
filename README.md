# ZIGGAZIGAH
## Cut ups for the video age.

Very alpha. Use at your own risk.

### What is this?

This is a couple of bash scripts used to generate a single .mp4 file which is a seemingly random series of clips sourced from media that you provide.

### Why on earth would anyone want this?

I go into a lengthier explaination in the devdiary but basically my interest is music performance. Bands of certain genres often use back projections during their performances to show something visually interesting while the performer is standing behind a laptop twiddling knobs.

There are other use cases of course, but this is my use case and I stand by this.

### What systems does this work on?

I have tested it on CentOS 7 and macOS Big Sur. In theory it should work on any Linux so long as you can satisfy the dependencies listed below. Hell it might even work on the Linux subsystem for Windows but I haven't tested that.

### Requirements

Off the top of my head.

```
sqlite
ffmpeg
ffprobe
```

I tested this script on CentOS 7, but I tried to make it generic enough to run anywhere. One of the reasons why it's not in Perl or Python.

There was some stuff in the docs for ffmpeg's handling of burning in subtitles that suggested it needs to be compiled with certain options. I think I grabbed a pre-built binary from ffmpeg rather than using the CentOS packaged versions so if your subtitles aren't appearing this is probably why.

I've added ffprobe to this list recently. It's available from the same place as ffmpeg. On macOS you can use homebrew.

### How to get started

Fair warning, this script is very alpha. Most of the working files use cwd, or ./tmp (note the ./) to store files.

Download the files, chmod +x the .sh files.

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

What you should see next is some scrolling text indicating that the script is going through the .srt files it has found line by line and inserting the data into the sqlite database. 

```
01:59:23.482 01:59:28.778 1444 Manhunter (1986) 720p.mkv
01:59:28.904 01:59:41.540 1445 Manhunter (1986) 720p.mkv
01:59:41.792 01:59:54.095 1446 Manhunter (1986) 720p.mkv
```

This can take some time depending on how much media you are ingesting.

To give you an idea -

1 subs file for a 2 hour movie takes about 3 minutes.
120 small subtitle files for a 30 minute tv shows took 2 hours.

Once that is complete, the script will exit. Next up you want to choose how you want to generate your video of randomness.

You have two options here.

```
./make_video.sh keywords "Leeds fragment boatyard iodine moon imagine shots dragon lunar"
```

This will search the database for keywords. It'll then use the timecodes to extract that section of video from the associated video file. If the keyword matches more than once the script will randomly choose one of the occurances for you.

Your output here will look something like this -

```
Mode: keywords Using keywords: Leeds fragment boatyard iodine moon imagine shots dragon lunar
00:14:13.636 that he would use later on Mrs. Leeds.
00:21:06.591 And the fragment of a palm off the nail of Mrs. Leeds' left big toe.
00:03:15.145 We should've talked at the boatyard.
00:42:11.312 but can't guarantee the iodine stains would fade out.
01:09:14.893 We've got about six more days till the next full moon.
00:27:20.464 if this pilgrim imagines he has a relationship with the moon,
00:49:57.195 I'm in the shots with Graham.
00:58:46.390 'I have seen with wonder and awe the strength of the Red Dragon.
00:04:27.634 This guy's on a lunar cycle.
Combining all the clips to ./tmp/20210520213829_final.mp4
Output video file is 24 seconds long.
Script took 0 minutes and 26 seconds to complete.
```

The second, and maybe more interesting mode, is purely random. You just tell it how many lines of random dialogue you want.

```
./make_video.sh random 10
```

And then your output might look like this.

```
Creating ./tmp
Mode: random Using 10 lines of random subtitles.

00:51:17.525 You'll wear a wire, one-way.
01:04:44.873 Kevin, why don't you run down to the water,
00:41:59.050 But the others. . .
00:21:45.755 - If we get lucky with that print, we're in,
00:22:00.144 Hey, look, I'm buying lunch.
00:48:33.694 It is not books in Lecktor's cell.
00:37:17.978 I need to know what kind of cutting tool he used.
01:49:02.236 He's got somebody in the house with him, Jack.
00:48:59.804 He reads Lounds in the Tattler.
01:07:06.056 And I knew it was him.
Combining all the clips to ./tmp/20210520213645_final.mp4
Output video file is 19 seconds long.
Script took 0 minutes and 33 seconds to complete.
```

### A word about the length of the video clips

There's a variable called TOLERANCE in the make_video.sh which determines how many frames either side of the chosen point in time the script will extract. This is to stop the video content strobing you into a seizure. If however you like to live dangerously you can change that TOLERANCE value which should give the audio a more constant disjointed feel.

### How do I get rid of the subtitles in the movie clips?

You can edit the make_video.sh script and change the SUBTTILES variable to 0 to turn that off.

### Where do I get the subtitle files from ?

For legal reasons, as in I don't know the legality of some of those sites, I'm not going to list any. But a quick google will show you a list of places that specialise in that sort of thing.

### My subtitles don't line up with my video!

You need to be super careful about what subtitle files you match with your videos. The script now checks for subtitle files where the timecodes exceed the length of the video content which was a show stopping bug I ran into recently. 

Consider the idea that the quality of your subtitle files will determine the quality of your finished video.

### Why does this script not download subtitles for me?

There are already 101 projects on github that will do this for you and quite honestly I don't have time to look into the legality of doing so.
