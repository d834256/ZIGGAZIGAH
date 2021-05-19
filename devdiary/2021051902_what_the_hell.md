# What the hell is this anyway? Thursday 20th August 2021.

When I am making music and trying to get out of the eternal damnation of being trapped in 2 bar loops, I think about performance. One of the done things in certain circles of live music performance is to have visuals made up of clips from tv shows and movies playing in the background while you are standing there trying to make standing behind a laptop twiddling knobs look cool. I do not have hours to spend hunting down clips that look cool and/or interesting. 

So, I want to automate this away, so I do not have to think about it.

## How would this work?

I have a bunch of DVDs of TV and Movies that I have ripped over the years. The media files live in a directory structure. I am not going to explain why anyone would want to store their video collection electronically, there are plenty of blog posts out there on this subject, the point is that it exists. Let us call this the SOURCE.

Next, I need to give the automation something to work with. I could just generate random time codes. 5:50->5:55 for example. And have the automation randomly pick a file from SOURCE and pull out a clip like that but that is too random. And I cannot guarantee that I’ll have dialogue at that time code. I will get to why I want audio of dialogue in a moment.

There exists on the information superhighway such a thing as repositories of subtitles. So, say you have an episode of the Twilight Zone. You could download the subtitles for that episode and play the video displaying text over the top from the subtitle file. These subtitle files are just text files with time codes in them. The format of these files looks something like this.

```
1
00:00:02,002 --> 00:00:04,294
[eerie music]

2
00:00:04,379 --> 00:00:07,798
(male presenter, off)
There is a
Fifth dimension,

3
00:00:07,882 --> 00:00:10,217
Beyond that which
Is known to man.

4
00:00:10,301 --> 00:00:13,429
It is a dimension
As vast as space

5
00:00:13,513 --> 00:00:16,306
And as timeless
As infinity.
```

Lovely metadata! 

I could just pick any random line from this file, pull out a video clip from that time code, but I want to be picky. I am going to give the automation something more to work with than pure randomness. I am going to give it a KEY PHRASE.

I want to provide a key phrase like, “RAIN ROCKET SPANNER”, and I want a script to take each word from the key phrase and pull-out video clips from my media matching dialogue matching those keywords. If more than one match for “RAIN” I will be ok with the automation picking a random timecode matching that.
Then the automation would splice together all the clips it had extracted into one longer form video clip.
Of course, I will not have video clips with audio just saying, “RAIN ROCKET SPANNER”, it will be mixed up with whatever other dialogue exists at that time code. It does however mean if I choose interesting words, I might end up with something more interesting. Also, a 3-word KEY PHRASE like that will only generate maybe 5 seconds of video but you get the idea.

## But why clips with dialogue?

Coming back to why I want dialogue. There exists this idea of “cut ups”. If you haven’t heard of cut ups I’ll leave you to google that as your homework for today. I had a vague notion that once I had my video assembled that the audio might reveal some audio treasure that could be sampled or used in some other way.

Hopefully, that explains my use case. There are other use cases of course.

Maybe you are doing the cut-up method of writing song lyrics and you want to find interesting phrases or ideas for writing lyrics.

Maybe you are a club, and you want some visuals to play on the screens around your club while the music is being played.

The idea is not limited to TV/Movies. Maybe you have a collection of music videos and you want to create a spliced horror show of video and audio?

Next: lets write some code

