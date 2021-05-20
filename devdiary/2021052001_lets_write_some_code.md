# Thursday 20th August 2021.
## lets write some code (design decisions)

```
#!/bin/bash
```

Yeah. You are wondering why the hell I’m writing this in bash and to be quite honest I don’t have a good answer for you other than this should be a shockingly simple script. If I wanted to do anything complicated, then of course I’d look at Python or Perl.

Other design decisions at this point.

* I’m going to use FFMPEG to chop the clips.
* Despite my saying I want my clips to be decided by keywords I also like a bit of randomness. So a completely random option is needed. Only argument would be the number of subtitle lines used.

With me so far? Jolly good. Let us proceed.

Some time passed. I wrote some code. 

I made some discoveries.

During my testing I was using a single movie file. It is amazing how, even randomly, you end up with the same frames of video. So, a to-do item is to add some checking to make sure the random clips or keyword choices and produce the same frames of video.

Sometimes it is nice to have longer random pieces of video. I added a TOLERANCE which means you get some extra lines of subtitles on either side of your key words. This also prevents the video from strobing quite as much with random videos.

Next: lets write the README.md and do some testing

