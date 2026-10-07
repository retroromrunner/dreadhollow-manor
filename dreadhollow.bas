 set tv ntsc
 set romsize 8k

 rem ****************************************************************
 rem DREADHOLLOW MANOR v5.0 - Complete game
 rem Haunted house exploration: 6 rooms, collect 3 relics per level.
 rem FIRE launches a lantern bolt to banish the wraith temporarily.
 rem
 rem House layout:
 rem   [0 Library]--E-->[1 Foyer]--E-->[2 Chapel]
 rem                      |
 rem                      S
 rem                      |
 rem   [5 Attic]<--W--[4 Crypt]<--W--[3 Cellar]
 rem
 rem Coordinate system (batari Basic standard kernel):
 rem - player0y: 1-88 usable, anchors sprite BOTTOM
 rem - Playfield: 32 cols x 12 rows, ROW 11 IS OFF-SCREEN
 rem - Safe player range: X [24, 130], Y [16, 74]
 rem - Doors: E/W y in [40,56], x>=128 / x<=26
 rem          N/S x in [68,88], y<=18 / y>=70
 rem ****************************************************************

 dim temp = a
 dim oldx = b
 dim oldy = c
 dim level = d
 dim ghost_spd = e
 dim spd_cnt = f
 dim lvl_show = h
 dim old_score = i
 dim room = m
 dim plives = n
 dim got = o
 dim gstate = p
 dim bolt_on = q
 dim bolt_dir = r
 dim ghost_on = s
 dim ghost_rt = t
 dim move_t = u
 dim death_t = v
 dim snd_t = w
 dim shoot_wait = x
 dim dir = y
 dim rflags = z

 score = 0
 scorecolor = $0E

 gstate = 0
 room = 1
 plives = 3
 got = 0
 level = 1
 rflags = 0
 bolt_on = 0
 bolt_dir = 2
 ghost_on = 1
 ghost_rt = 0
 move_t = 0
 death_t = 0
 snd_t = 0
 shoot_wait = 0
 ghost_spd = 24
 spd_cnt = 0
 dir = 2

 player0x = 80
 player0y = 48
 player1x = 40
 player1y = 32
 missile0x = 200
 missile0y = 200
 missile0height = 4
 ballx = 200
 bally = 200

 COLUP0 = $9E
 COLUP1 = $0E
 COLUPF = $55
 COLUBK = $00

main
 temp = gstate
 if temp = 0 then goto do_title
 if temp = 1 then goto do_play
 if temp = 2 then goto do_dead
 if temp = 3 then goto do_over
 if temp = 4 then goto do_win
 goto main

do_title
 COLUBK = $00
 COLUPF = $55
 scorecolor = $1E
 playfield:
..............XX................
.............XXXX...............
.............XXXX...............
............XXXXXX..............
...........XXXXXXXX.............
..........XXXXXXXXXX............
.........XXXXXXXXXXXX...........
.........XXXXXXXXXXXX...........
.........XX..XX..XX.............
.........XXXXXXXXXXXX...........
.........XXX....XXX.............
................................
end
 player0:
%00000000
end
 player1:
%00000000
end
 if joy0fire then gosub start_game
 drawscreen
 goto main

do_over
 COLUBK = $00
 COLUPF = $55
 scorecolor = $36
 AUDV0 = 0
 playfield:
................................
................................
...XXXX..XXXX...XX...XX..XXXX...
...X.....X..X...X.X.X.X..X......
...X.XX..XXXX...X..X..X..XXX....
...X..X..X..X...X.....X..X......
...XXXX..X..X...X.....X..XXXX...
................................
................................
................................
................................
................................
end
 player0:
%00000000
end
 player1:
%00000000
end
 if joy0fire then gosub start_game
 drawscreen
 goto main

do_win
 COLUBK = $00
 COLUPF = $2C
 scorecolor = $2C
 playfield:
................................
................................
....X...X..XXX..X...X..XXXX.....
....X...X.X...X.X...X..X........
.....X.X..X...X.X...X..XXX......
......X...X...X.X...X..X........
......X....XXX...XXX...XXXX.....
................................
................................
................................
................................
................................
end
 player0:
%00000000
end
 player1:
%00000000
end
 if joy0fire then gosub start_game
 drawscreen
 goto main

do_dead
 death_t = death_t + 1
 COLUBK = $00
 COLUPF = $00
 rem Flash player red on/off every 8 frames (classic Atari style)
 temp = death_t
 temp = temp / 8
 temp = temp & 1
 if temp = 0 then COLUP0 = $30 else COLUP0 = $00
 player0:
%00111100
%01111110
%01111110
%00111100
%00111100
%01111110
%01011010
%10100101
end
 player1:
%00000000
end
 if death_t > 120 then death_t = 0 : gosub respawn : if plives > 0 then gstate = 1
 drawscreen
 goto main

do_play
 COLUBK = $00
 temp = level
 temp = temp & 3
 if temp = 1 then COLUPF = $55
 if temp = 2 then COLUPF = $25
 if temp = 3 then COLUPF = $85
 if temp = 0 then COLUPF = $C5
 rem Flash score yellow for 3 sec after level up (level shown by wall color)
 if lvl_show > 0 then lvl_show = lvl_show - 1 : scorecolor = $1E else scorecolor = $0E
 temp = room
 if temp = 0 then gosub room0
 if temp = 1 then gosub room1
 if temp = 2 then gosub room2
 if temp = 3 then gosub room3
 if temp = 4 then gosub room4
 if temp = 5 then gosub room5

 rem Player ghost (white)
 COLUP0 = $9E
 player0:
%00111100
%01111110
%01111110
%00111100
%00111100
%01111110
%01011010
%10100101
end

 rem Wraith (white)
 COLUP1 = $0E
 if ghost_on = 0 then goto no_ghost
 player1:
%00111100
%01111110
%11111111
%11111111
%11111111
%11111111
%10101010
%00000000
end
 goto ghost_done
no_ghost
 player1:
%00000000
end
ghost_done

 rem Save position for obstacle collision
 oldx = player0x
 oldy = player0y

 rem Movement (also tracks facing for bolt)
 if joy0right then player0x = player0x + 1 : bolt_dir = 1
 if joy0left then player0x = player0x - 1 : bolt_dir = 3
 if joy0up then player0y = player0y - 1 : bolt_dir = 0
 if joy0down then player0y = player0y + 1 : bolt_dir = 2

 rem Hard clamp to safe visible area
 if player0x < 24 then player0x = 24
 if player0x > 130 then player0x = 130
 if player0y < 16 then player0y = 16
 if player0y > 74 then player0y = 74

 rem Obstacle collision (coordinate-based, revert if inside)
 gosub check_obstacles

 rem Room exits (4-direction, contiguous)
 gosub check_exits

 rem Relic pickup (level-aware)
 gosub check_relic

 rem Draw relic if present
 gosub draw_relic

 rem Fire lantern bolt
 if shoot_wait > 0 then shoot_wait = shoot_wait - 1
 if joy0fire && shoot_wait = 0 && bolt_on = 0 then bolt_on = 1 : missile0x = player0x + 3 : missile0y = player0y - 4 : shoot_wait = 20 : AUDV0 = 4 : AUDC0 = 8 : AUDF0 = 10 : snd_t = 3

 if bolt_on = 1 then gosub move_bolt

 rem Wraith AI (phases through walls)
 if ghost_on = 1 then gosub move_ghost

 rem Wraith catches player
 if ghost_on = 1 then if collision(player0,player1) then gstate = 2 : death_t = 0 : player1y = 200 : AUDV0 = 6 : AUDC0 = 8 : AUDF0 = 6 : snd_t = 30

 rem Bolt banishes wraith
 if bolt_on = 1 then if collision(missile0,player1) then ghost_on = 0 : ghost_rt = 0 : bolt_on = 0 : missile0y = 200 : score = score + 50 : AUDV0 = 6 : AUDC0 = 3 : AUDF0 = 18 : snd_t = 12

 rem Wraith respawn
 if ghost_on = 0 then ghost_rt = ghost_rt + 1
 if ghost_rt > 200 then ghost_on = 1 : ghost_rt = 0 : player1x = 40 : player1y = 32

 rem Sound decay
 if snd_t > 0 then snd_t = snd_t - 1
 rem Level-up ascending (only when snd_t>30, safe: other sounds use <=30)
 if snd_t > 50 then AUDF0 = 22
 if snd_t <= 50 && snd_t > 40 then AUDF0 = 15
 if snd_t <= 40 && snd_t > 30 then AUDF0 = 9
 if snd_t = 0 then AUDV0 = 0

 rem Level complete -> next level
 if got >= 3 then gosub next_level

 drawscreen
 goto main

 rem === ROOMS (12 rows x 32 cols) ===
 rem Row 11 off-screen. E/W door gaps at rows 5-6.
 rem N door gap: row 0 cols 14-17. S door gap: row 10 cols 14-17.

room0
 rem Library - East door only. Bookshelves north/south.
 playfield:
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
X..............................X
X..XXXXXXXXXXXXXXXXXXXXXXXXXX..X
X..............................X
X..............................X
X...............................
X...............................
X..............................X
X..XXXXXXXXXXXXXXXXXXXXXXXXXX..X
X..............................X
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
................................
end
 return

room1
 rem Foyer - West, East, South. Open hub.
 playfield:
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
X..............................X
X..............................X
X..............................X
X..............................X
................................
................................
X..............................X
X..............................X
X..............................X
XXXXXXXXXXXXXX....XXXXXXXXXXXXXX
................................
end
 return

room2
 rem Chapel - West door only. Pews left/right.
 playfield:
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
X..............................X
X....XX................XX......X
X....XX................XX......X
X..............................X
...............................X
...............................X
X..............................X
X....XX................XX......X
X....XX................XX......X
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
................................
end
 return

room3
 rem Cellar - North, East. Barrels.
 playfield:
XXXXXXXXXXXXXX....XXXXXXXXXXXXXX
X..............................X
X....XXXX....XXXX..............X
X..............................X
X..............................X
X...............................
X...............................
X..............................X
X.........XXXX....XXXX.........X
X..............................X
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
................................
end
 return

room4
 rem Crypt - West, East. Tombs.
 playfield:
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
X..............................X
X....XXXXX......XXXXX..........X
X..............................X
X..............................X
...............................X
...............................X
X..............................X
X....XXXXX......XXXXX..........X
X..............................X
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
................................
end
 return

room5
 rem Attic - West door only. Crates.
 playfield:
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
X..............................X
X.....XXXX.....................X
X..............................X
X..............................X
...............................X
...............................X
X..............................X
X...........XXXX...............X
X..............................X
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
................................
end
 return

check_obstacles
 rem Revert to oldx/oldy if player inside an obstacle rect
 temp = room
 if temp = 0 then goto obs0
 if temp = 2 then goto obs2
 if temp = 3 then goto obs3
 if temp = 4 then goto obs4
 if temp = 5 then goto obs5
 return
obs0
 rem Library bookshelves: x[28,124], y[20,34] and y[60,72]
 if player0y >= 20 && player0y <= 34 then if player0x >= 28 && player0x <= 124 then player0x = oldx : player0y = oldy : return
 if player0y >= 60 && player0y <= 72 then if player0x >= 28 && player0x <= 124 then player0x = oldx : player0y = oldy : return
 return
obs2
 rem Chapel pews: x[36,48] and x[108,120], y[22,38] and y[60,74]
 if player0y >= 22 && player0y <= 38 then if player0x >= 36 && player0x <= 48 then player0x = oldx : player0y = oldy : return
 if player0y >= 22 && player0y <= 38 then if player0x >= 108 && player0x <= 120 then player0x = oldx : player0y = oldy : return
 if player0y >= 60 && player0y <= 74 then if player0x >= 36 && player0x <= 48 then player0x = oldx : player0y = oldy : return
 if player0y >= 60 && player0y <= 74 then if player0x >= 108 && player0x <= 120 then player0x = oldx : player0y = oldy : return
 return
obs3
 rem Cellar barrels
 if player0y >= 24 && player0y <= 36 then if player0x >= 40 && player0x <= 60 then player0x = oldx : player0y = oldy : return
 if player0y >= 24 && player0y <= 36 then if player0x >= 72 && player0x <= 92 then player0x = oldx : player0y = oldy : return
 if player0y >= 58 && player0y <= 70 then if player0x >= 56 && player0x <= 76 then player0x = oldx : player0y = oldy : return
 if player0y >= 58 && player0y <= 70 then if player0x >= 88 && player0x <= 108 then player0x = oldx : player0y = oldy : return
 return
obs4
 rem Crypt tombs
 if player0y >= 22 && player0y <= 36 then if player0x >= 40 && player0x <= 64 then player0x = oldx : player0y = oldy : return
 if player0y >= 22 && player0y <= 36 then if player0x >= 92 && player0x <= 116 then player0x = oldx : player0y = oldy : return
 if player0y >= 60 && player0y <= 74 then if player0x >= 40 && player0x <= 64 then player0x = oldx : player0y = oldy : return
 if player0y >= 60 && player0y <= 74 then if player0x >= 92 && player0x <= 116 then player0x = oldx : player0y = oldy : return
 return
obs5
 rem Attic crates
 if player0y >= 22 && player0y <= 34 then if player0x >= 48 && player0x <= 68 then player0x = oldx : player0y = oldy : return
 if player0y >= 58 && player0y <= 70 then if player0x >= 88 && player0x <= 108 then player0x = oldx : player0y = oldy : return
 return

check_exits
 rem East: x>=128, y in [40,56]
 if player0x >= 128 then if player0y >= 40 then if player0y <= 56 then goto exit_east
 rem West: x<=26, y in [40,56]
 if player0x <= 26 then if player0y >= 40 then if player0y <= 56 then goto exit_west
 rem North: y<=18, x in [68,88]
 if player0y <= 18 then if player0x >= 68 then if player0x <= 88 then goto exit_north
 rem South: y>=70, x in [68,88]
 if player0y >= 70 then if player0x >= 68 then if player0x <= 88 then goto exit_south
 return

exit_east
 temp = room
 if temp = 0 then room = 1 : player0x = 28 : player0y = 48 : gosub reset_ghost : return
 if temp = 1 then room = 2 : player0x = 28 : player0y = 48 : gosub reset_ghost : return
 if temp = 3 then room = 4 : player0x = 28 : player0y = 48 : gosub reset_ghost : return
 if temp = 4 then room = 5 : player0x = 28 : player0y = 48 : gosub reset_ghost : return
 return

exit_west
 temp = room
 if temp = 1 then room = 0 : player0x = 126 : player0y = 48 : gosub reset_ghost : return
 if temp = 2 then room = 1 : player0x = 126 : player0y = 48 : gosub reset_ghost : return
 if temp = 4 then room = 3 : player0x = 126 : player0y = 48 : gosub reset_ghost : return
 if temp = 5 then room = 4 : player0x = 126 : player0y = 48 : gosub reset_ghost : return
 return

exit_north
 temp = room
 if temp = 3 then room = 1 : player0x = 78 : player0y = 68 : gosub reset_ghost : return
 return

exit_south
 temp = room
 if temp = 1 then room = 3 : player0x = 78 : player0y = 20 : gosub reset_ghost : return
 return

reset_ghost
 player1x = 100
 player1y = 32
 ghost_on = 1
 ghost_rt = 0
 return

check_relic
 rem Relics always in rooms 0,2,4 (simplified, no rotation)
 if room = 0 then if !rflags{0} then goto try_pickup
 if room = 2 then if !rflags{2} then goto try_pickup
 if room = 4 then if !rflags{4} then goto try_pickup
 return
try_pickup
 if player0x > 70 && player0x < 90 then if player0y > 40 && player0y < 56 then gosub get_relic
 return

draw_relic
 rem Relics always in rooms 0,2,4
 if room = 0 then if !rflags{0} then goto do_draw
 if room = 2 then if !rflags{2} then goto do_draw
 if room = 4 then if !rflags{4} then goto do_draw
 ballx = 200
 return
do_draw
 ballx = 80
 bally = 48
 ballheight = 8
 return

get_relic
 temp = room
 if temp = 0 then rflags{0} = 1
 if temp = 1 then rflags{1} = 1
 if temp = 2 then rflags{2} = 1
 if temp = 3 then rflags{3} = 1
 if temp = 4 then rflags{4} = 1
 if temp = 5 then rflags{5} = 1
 got = got + 1
 score = score + 100
 AUDV0 = 8 : AUDC0 = 12 : AUDF0 = 15 : snd_t = 10
 ballx = 200
 return

next_level
 level = level + 1
 got = 0
 rflags = 0
 score = score + 500
 if ghost_spd > 7 then ghost_spd = ghost_spd - 5 else ghost_spd = 2
 AUDV0 = 8 : AUDC0 = 12 : AUDF0 = 22 : snd_t = 60
 lvl_show = 180
 rem Move player to Foyer (no relic there) to avoid auto-collect
 room = 1
 player0x = 80
 player0y = 48
 return

move_bolt
 temp = bolt_dir
 if temp = 0 then missile0y = missile0y - 2
 if temp = 1 then missile0x = missile0x + 2
 if temp = 2 then missile0y = missile0y + 2
 if temp = 3 then missile0x = missile0x - 2
 if missile0x < 16 then bolt_on = 0 : missile0y = 200 : return
 if missile0x > 140 then bolt_on = 0 : missile0y = 200 : return
 if missile0y < 10 then bolt_on = 0 : missile0y = 200 : return
 if missile0y > 80 then bolt_on = 0 : missile0y = 200 : return
 return

move_ghost
 spd_cnt = spd_cnt + 1
 if spd_cnt < ghost_spd then return
 spd_cnt = 0
 if player1x < player0x then player1x = player1x + 1
 if player1x > player0x then player1x = player1x - 1
 if player1y < player0y then player1y = player1y + 1
 if player1y > player0y then player1y = player1y - 1
 if player1x < 24 then player1x = 24
 if player1x > 130 then player1x = 130
 if player1y < 16 then player1y = 16
 if player1y > 74 then player1y = 74
 return

respawn
 player0x = 80
 player0y = 48
 player1x = 40
 player1y = 32
 ghost_on = 1
 bolt_on = 0
 missile0y = 200
 ballx = 200
 COLUP0 = $9E
 plives = plives - 1
 if plives = 0 then gstate = 3
 return

start_game
 room = 1
 plives = 3
 got = 0
 level = 1
 rflags = 0
 score = 0
 old_score = 0
 lvl_show = 0
 bolt_on = 0
 bolt_dir = 2
 ghost_on = 1
 ghost_rt = 0
 move_t = 0
 death_t = 0
 snd_t = 0
 shoot_wait = 0
 ghost_spd = 24
 spd_cnt = 0
 dir = 2
 player0x = 80
 player0y = 48
 player1x = 40
 player1y = 32
 missile0x = 200
 missile0y = 200
 ballx = 200
 bally = 200
 gstate = 1
 return
