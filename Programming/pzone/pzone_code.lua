
function change_toggle() arcademode=not arcademode end

function _init()
  --init font
  charstart=192
  charlist=' !"#$%&\'()*+,-./0123456789:;<=>?@abcdefghijklmnopqrstuvwxyz[\\]^_'
  defaultwidth=6
  charwidth={[' ']=4,['!']=2,['"']=4,['%']=5,['"']=2,['(']=4,[')']=4,[',']=2,['.']=2,['/']=4,[':']=2,[';']=2,['<']=4,['>']=4,['?']=5,i=2,['[']=4,['\\']=4,[']']=4}
  charmap={}
  for i=1,#charlist do
      char=sub(charlist,i,i)
      charmap[char]=i+charstart-1
      if(charwidth[char]==nil)charwidth[char]=defaultwidth
  end

  menuitem(1, 'color palette', change_toggle)
		entities = {}
		bullets = {}
		genworld()
  --camera stuff
  campos = {0,0,0}--offset for player cam
		--camera centering from player pos
		camera_z = -10
		camera_x = 0
		camera_y = 2
		camera_focal_length = 1 --useless?
		camera_fov = 45
		theta = 0.8
		width = 128
		height = 128
		renderdist = 80 --how far away t draw stuff
		collision = false
		init_bg() --background
		update = dr_menu
  pvec = {0,0,20}
  insight = false -- if enemy is in sights
  hit = 0
  lives = 3
  score = 0
  tang = 0 --angle toward target
  rsweep = 0 --radar sweep animation
  difficulty = 0
  gamemode = 1
  extralife = true
  arcademode = true --colors/colours
end


--menu() and game()
function dr_menu()
	up_entities()
	theta+=0.002
	drawthing(player,move({0,0,0},0,0,-0.5))
	drawthing(turret,move({0,0,0.5},rot,0.7,-0.5))

	--start animation
	if(btnp(🅾️) or btnp(❎)) starting=true
	if starting then
	 if (theta>0.5) theta-=0.008
	 if (theta<0.5) theta+=0.008
	else
 	--change modes
 	if(btnp(⬅️)) gamemode -= 1
 	if(btnp(➡️)) gamemode += 1
 	if(gamemode < 1) gamemode = 3
 	if(gamemode > 3) gamemode = 1
 	toprnt = ""
 	if flr(theta*30)%2==0 then
  	if(gamemode == 1) toprnt = "< arcade >"
  	if(gamemode == 2) toprnt = "< onslaught >"
  	if(gamemode == 3) toprnt = "< target practice >"
  end
  text(62-#toprnt*2.5,10,toprnt)
 	--draw title
 	spr(64,10,20,14,4)
 	print("z/x to fire; arrows to steer",3,120,11)
	end
	if flr(theta*50)/50==0.5 and starting then --start game
		addent("player",{0,0,0})
	 update=up_entities
	end
end

function _update()
 radar_tgt = {}
	if arcademode then
	 pal()
 	cls()
	else
 	cls(5)
	 pal(0,5)
	 pal(3,15)
	 pal(11,7)
	 pal(2,6)
	 pal(8,7)
	end
	--angle rollover
	theta = rollover(theta)
	update_bg()
	update()
end

--add things to world
function genworld()
	while #entities<30 do
	 st = false
	 rndx = rnd(150)-75
	 rndz = rnd(150)-75
	 t = flr(rnd(3))
	 if(rndx>-5 and rndx<5) st = true
	 if(rndz>-5 and rndz<5) st = true
	 if st==false then
	  if(t < 2) str = "cube"
	  if(t == 2) str = "pyramid"
 		addent(str, {rndx,0,rndz},0.3)
  end
	end
end

function rollover(var)
 if var > 1.001 then var -= 1 end
 if var < -0.001 then var += 1 end
 return var
end
-->8
--3d functions
--i know the 3d stuff is inefficient..

--change coords in a direction 
function move(vec3,ang,dis,y)
 --y is up or down
 if(y == nil) y = 0
 local newv={vec3[1],vec3[2],vec3[3]}
 newv[2] += y
 newv[1] -= sin(ang)*dis
 newv[3] -= cos(ang)*dis
 return newv
end


function drawthing(thing,vec3,ang)
 if(vec3==nil) vec3={0,0,0}
 angle=ang
 if(ang==nil) angle=0
 angle=angle*-1
	resvec(vec3)
	for i=1,#thing do
  plane = thing[i]
  
  if #plane>2 then --3+ sides
   for n=1,#plane do
    if n == #plane then
   		draw_line(plane[#plane], plane[1])
    else
     draw_line(plane[n], plane[n+1])
    end
   end
  elseif #plane == 2 then   --line
   draw_line(plane[1], plane[2])
  elseif #plane == 1 then   --point
   draw_point(plane[1])
  end
  
 end
 angle=0
end

--change draw position
function resvec(vec3)
 if vec3==nil then
 	vec=campos
 else
 	vec={campos[1]+vec3[1],
 	     campos[2]+vec3[2],
 	     campos[3]+vec3[3]}
 end
end

function tan(v)
		return sin(v) / cos(v)
end

function perspective(p)
		x = p[1]
		y = p[2]
		z = p[3]
		--rotate
		local xx = x
		local zz = z
  x = xx*cos(angle) - zz*sin(angle)
  z = zz*cos(angle) + xx*sin(angle)
  --camera offset
  x += vec[1]
  y += vec[2]
  z += vec[3]
		--adjust x and z
		x_rot = x * cos(theta) - z * sin(theta)
		z_rot = x * sin(theta) + z * cos(theta)

		x = x_rot 
		y -=        camera_y  --up and down
		z = z_rot

	 -- where does the ray from
	 -- the camera focus to
	 -- (x, y, z) intersect the
	 -- lens?
	 dz = z - camera_z
	 out_z =  camera_focal_length --+ camera_z

	 -- slope of xz
	 -- note:
	 --   dx is just x
	 --   x initial is 0
	 if(dz<1) return--try to fix
	 m_xz = x / dz
	 m_yz = y / dz
	 
	 out_x = m_xz * out_z
	 out_y = m_yz * out_z
	 return { out_x, out_y }
end

function _map(v, a, b, c, d)
		partial = (v - a) / (b - a)
		return partial * (d - c) + c	
end

function coords_to_px(coords)
  if(coords==nil) return--try to fix
		x = coords[1]
		y = coords[2]
		
		radius = camera_focal_length *
						tan(camera_fov / 2 / 360)
		
		pixel_x = _map(x, -radius, radius, 0, width)
		pixel_y = _map(y, -radius, radius, 0, height)
		return { pixel_x, pixel_y }
end


function draw_line(p1, p2)
	px_1 = coords_to_px(perspective(p1))
	px_2 = coords_to_px(perspective(p2))
 if(px_1==nil or px_2==nil) return --try to fix
	line(px_1[1], px_1[2],
	     px_2[1], px_2[2], 11)
end

function draw_point(p)
	px = coords_to_px(perspective(p))
 if(px==nil) return --try to fix
	pset(px[1], px[2], 11)
end

-->8
--player

function up_player(e)
 if(score>=5000 and extralife) extralife = false lives += 1
 if hit>0 then --hit
  dr_hud(e)
  if lives>0 or hit>1 then
   hit -= 1
   if(hit == 0) lives -= 1
  else --game over screen
   text(39,64,"game over")
   scorestr = "score: "..tostr(score)
   text(62-#scorestr*2.5,72,scorestr)
   if(btnp(❎)) _init()
  end
  return
 end
 if checkhits(e) and hit==0 then
  hit = 70 explode(e,20)
  nv3 = {}
  nv3[1] = e.vec3[1] + rnd(2)-1
  nv3[2] = e.vec3[2] + rnd(2)-1
  nv3[3] = e.vec3[3] + rnd(2)-1
  addent("part",nv3,rnd(1),dist)
  return
 end
	dr_hud(e)
 if camera_z<-2.6 then --tank
 	drawthing(player,move(e.vec3,0,0,-0.5),e.ang)
 	drawthing(turret,move(e.vec3,e.tr,0.5-e.fa,-0.5),e.tr)
 else --hud
 	camera_z=-2-e.fa
  dr_crosshair(e)
 end
 pvec = e.vec3
 if(e.mode == nil) e.mode = 0
 e.rld-=1


 --fire
 if(e.fa>0.1) e.fa = e.fa / 1.2
 if e.rld<1 and (btn(🅾️) or btn(❎) or btn(⬇️,1)) then
  fire("bullet",move(e.vec3,e.tr,1.4,-0.7),e.tr)
  e.rld = 30
  e.fa = 0.5
  sfx(8)
 end
 --drive
 if btn(⬆️) then
		collision=false
  --collision detection
  collision=checkcollisions(e,0.3)
  if collision!=true then
   e.vec3=move(e.vec3,e.ang,0.3)
   if(stat(49)==3) sfx(4,3)
  end
 elseif btn(⬇️) then
  collision=checkcollisions(e,-0.1)
  if(collision!=true)e.vec3=move(e.vec3,e.ang,-0.1)
 end
 if(stat(49)!=3 and not btn(⬆️)) sfx(3,3)
 --turret motion
 e.tr = rollover(e.tr)
 if(btn(⬅️,1)) e.tr-=0.004
 if(btn(➡️,1)) e.tr+=0.004
 if(btn(⬅️)) e.ang-=0.004 e.tr-=0.004
 if(btn(➡️)) e.ang+=0.004 e.tr+=0.004
 if btn(⬆️,1) then
  --rotation code
  pang=e.tr
  if(flr(pang*100) == flr(e.ang*100)) e.ang = pang
  if pang<e.ang then
   if e.ang>0.75 and pang<0.25 then
    e.ang+=0.004
   else
    e.ang-=0.004
   end
  elseif pang>e.ang then
   if e.ang<0.25 and pang>0.75 then
    e.ang-=0.004
   else
    e.ang+=0.004
   end
  end
 end
 
 theta=e.tr-0.5
 if e.mode == 0 then --fst person
  if(btnp(🅾️,1)) e.mode = 1
  if(camera_z<-2)camera_z+=1
  if(camera_y>0.5)camera_y-=0.5
  campos[3]=e.vec3[3]*-1
  campos[1]=e.vec3[1]*-1
  
 else --3rd person
  if(btnp(🅾️,1)) e.mode = 0
  if(camera_z>-10)camera_z-=1
  if(camera_y<2)camera_y+=0.5
  campos[3]=e.vec3[3]*-1
  campos[1]=e.vec3[1]*-1
 end
end

--draw hud
function dr_hud(e)
 rectfill(0,0,127,20,0)
	if(collision) text(2,2,"collision")
	if gamemode!=3 then
	 text(77,10,tostr(score))
 	--lives
 	for i=1, lives do spr(2,2+12*i,10,2,1) end
 end
 --radar
 spr(0,57,2,2,2)
 line(64,10,64+cos(rsweep)*5,10+sin(rsweep)*5,8)
 rsweep-=0.02
 
 for contact in all(radar_tgt) do
  pset(64+cos(contact.ang)*contact.rng,
       10+sin(contact.ang)*contact.rng,11)
 end
 
 --cracks
 if(hit == 0) cracks={{64,64,64,64}}
 if hit>0 then
  if hit == 70 then
   
   for d=1, 10 do
    rndcrk=cracks[flr(rnd(#cracks))+1]
    add(cracks,{rndcrk[3],
                rndcrk[4],
                rndcrk[3]+rnd(50)-25,
                rndcrk[4]+rnd(50)-25,})
   end
  end
  for c in all(cracks) do
   line(c[1],c[2],c[3],c[4],11)
  end
 end

 	--show direction facing
 x=cos(e.ang-e.tr-0.25)*-4
 y=sin(e.ang-e.tr-0.25)*4
 line(118-x,10-y,118+x,10+y,2)
 line(118,10,118,5,8)
end

function dr_crosshair(e)
	line(0,20,127,20,11) --top
	line(64,30,64,50)
	line(64,107,64,87)
	line(48,50,79,50)
	line(48,87,79,87)
	
	if insight then
 	line(48,50,52,60)
 	line(48,87,52,77)
 	line(79,50,75,60)
 	line(79,87,75,77)
 else
 	line(48,50,48,60)
 	line(48,87,48,77)
 	line(79,50,79,60)
 	line(79,87,79,77)
 end
 insight = false
end
-->8
--models
--ufo

ufov = {
--lr ud bf
 {0, 0, 0 },--1  bottom point
 {0,0.75,0 },--2  top point
 {1,0.25,0},--3  left
 {-1,0.25,0},--4  right
 {0,0.25, 1},--5 back
 {0,0.25,-1},--6 front
 {-0.7,0.25,0.7},--7 bk rt
 {0.7,0.25,0.7},--8 bk lft
 {0.7,0.25,-0.7},--9 ft lft
 {-0.7,0.25,-0.7},--10 ft rt
}

v = ufov

ufo = {

 { v[1], v[3], v[2], v[4]},
 { v[5], v[7], v[4], v[10], v[6], v[9], v[3], v[8]},
 { v[1], v[5], v[2], v[6]},
 { v[1], v[7], v[2], v[9]},
 { v[1], v[8], v[2], v[10]},
}

--enemy supertank
supertankv = {
 --x   y   z
 --left
 { 1,  0.2,  1.5},--1
 { 1, -0.6,  1.5},--2
 { 1, -0.6, -1.5},--3
 --right
 {-1,  0.2,  1.5},--4
 {-1, -0.6,  1.5},--5
 {-1, -0.6, -1.5},--6
 --turret top
 {-0.2,  0.6,  1.0},--7
 { 0.2,  0.6,  1.0},--8
 {-0.4,  0.6,  1.2},--9
 { 0.4,  0.6,  1.2},--10
 {-0.4,  0.6,  1.5},--11
 { 0.4,  0.6,  1.5},--12
 --turret bottom
 {-0.2,  0.2,  1.0},--13
 { 0.2,  0.2,  1.0},--14
 {-0.4,  0.2,  1.2},--15
 { 0.4,  0.2,  1.2},--16
 {-0.4,  0.2,  1.5},--17
 { 0.4,  0.2,  1.5},--18
 --antenna
 { 0.4,  1.5,  1.5},--19
}

v = supertankv

supertank = {
 --goes in u shape: right-left-left-right
 --bottom track
 {v[1], v[2], v[3] },--left
 {v[4], v[5], v[6] },--right
 {v[4], v[1] },--top line
 {v[2], v[5] },--bottom line
 {v[3], v[6] },--front
 {v[11], v[9], v[7], v[8], v[10], v[12] },--turret top
 {v[17], v[15], v[13], v[14], v[16], v[18] },--turret bottom
 --lines on turret
 {v[11], v[17]},
 {v[9], v[15]},
 {v[7], v[13]},
 {v[8], v[14]},
 {v[10], v[16]},
 {v[12], v[18]},
 {v[19], v[18]}, --antenna
}

--dish

dishv = {
 { 0,     0.3,    0},--1 base
 { 0,     0.5,  0},--1 botom mid
 { 0.1,     0.6,  0.05},--left
 { -0.1,     0.6,  0.05},--right
 { 0.1,     0.65,  0.05},--left
 { -0.1,     0.65,  0.05},--right
 { 0,     0.7,  0},--top
}

v = dishv
dish = {
 { v[1], v[2]},--base
 { v[5], v[3], v[2], v[4], v[6], v[7]},--base
}

--dot
dot = {
 {{0,0,0}}
}

--bullet
bulletv = {
 { 0,     1,    -1},--1 frnt
 { 0.1,   0.9,  0},--2 bl
 { 0.1,   1.1,  0},--3 tl
 { -0.1,  0.9,  0},--4 tr
 { -0.1,  1.1,  0},--5 br
}

v = bulletv
bullet = {
 { v[2], v[3], v[5], v[4] },--back
 { v[1], v[2]},
 { v[1], v[3]},
 { v[1], v[4]},
 { v[1], v[5]},
}

--player tank
playerv = {
 --x   y   z
 --bottom tracks
 { 1,  0.2,  2.4},--1 btl
 { 1,  0.2, -1.4},--2 ftl
 { 1, -0.4,  2},--3 bbl
 { 1, -0.4, -1},--4 fbl
 {-1,  0.2,  2.4},--5 btr
 {-1,  0.2, -1.4},--6 ftr
 {-1, -0.4,  2},--7 bbr
 {-1, -0.4, -1},--8 fbr
 
 --top tracks
 {0.8,  0.5, 1.8},--9 btl
 {-0.8, 0.5, 1.8},--10 btr
 {0.6,  0.5, -0.7},--11 ftl
 {-0.6, 0.5, -0.7},--12 ftr
 
}

v = playerv

player = {
 --goes in u shape: right-left-left-right
 --bottom track
 {v[7], v[3] },--back
 {v[1], v[2], v[4], v[3] },--left
 {v[5], v[7], v[8], v[6] },--right
 {v[8], v[4]},--front

 --top track
 {v[1], v[9], v[10], v[5] },--rear
 {v[9], v[11]},--left
 {v[10], v[12] },--right
 {v[11], v[12], v[6], v[2] },--front
 
}


--player turret

turretv = {
 --barrel
 { 0.1,  1.0,  0.5},--1
 { 0.1,  1.0,  -2},--2
 { 0.1,  0.8,  0},--3
 { 0.1,  0.8,  -2},--4
 {-0.1,  1.0,  0.5},--5
 {-0.1,  1.0,  -2},--6
 {-0.1,  0.8,  0},--7
 {-0.1,  0.8,  -2},--8
 --base
 {0.8,  0.5, 1.8},--9 bbl
 {-0.8, 0.5, 1.8},--10 bbr
 {0.6,  0.6, -0.7},--11 ftl
 {-0.6, 0.6, -0.7},--12 ftr
 
 --top
 {0.6,  1.4, 1.5},--13 btl
 {-0.6, 1.4, 1.5},--14 btr
}

v = turretv
turret = {
 { v[5], v[7], v[3], v[1] },--back
 { v[1], v[2]},--left
 { v[4], v[3]},--left
 { v[5], v[6] },--right
 { v[7], v[8] },--right
 { v[8], v[4], v[2], v[6] },--front
 {v[11], v[12]},--front
 {v[13], v[9], v[11] },--left
 {v[14], v[10], v[12] },--left
 {v[9], v[13], v[14], v[10] },--back
}


--enemy tank
tankv = {
 --x   y   z
 --bottom tracks
 { 1.2,  0,  2.2},--1 btl
 { 1.2,  0, -1.2},--2 ftl
 { 1, -0.4,  2},--3 bbl
 { 1, -0.4, -1},--4 fbl
 {-1.2,  0,  2.2},--5 btr
 {-1.2,  0, -1.2},--6 ftr
 {-1, -0.4,  2},--7 bbr
 {-1, -0.4, -1},--8 fbr
 
 --top tracks
 {0.8,  0.4, 1.8},--9 btl
 {-0.8, 0.4, 1.8},--10 btr
 {0.6,  0.4, 0.2},--11 ftl
 {-0.6, 0.4, 0.2},--12 ftr
 
 --turret
 {0.6,  1.1, 1.7},--13 btl
 {-0.6, 1.1, 1.7},--14 btr
}

v = tankv

tank = {
 --goes in u shape: right-left-left-right
 --bottom track
 {v[7], v[3] },--back
 {v[1], v[2], v[4], v[3] },--left
 {v[5], v[7], v[8], v[6] },--right
 {v[8], v[4]},--front

 --top track
 {v[1], v[9], v[10], v[5] },--rear
 {v[9], v[11]},--left
 {v[2], v[1] },--left
 {v[10], v[12] },--right
 {v[6], v[5] },--right
 {v[11], v[12], v[6], v[2] },--front
 
 --turret
 {v[11], v[12], v[14], v[13] },--front
 {v[13], v[9]},--left
 {v[11], v[9]},--left
 {v[14], v[10], v[12] },
}

--cannon

cannonv = {
 { 0.1,  1.0,  1.5},
 { 0.1,  1.0,  -1},
 { 0.1,  0.8,  1},
 { 0.1,  0.8,  -1},
 {-0.1,  1.0,  1.5},
 {-0.1,  1.0,  -1},
 {-0.1,  0.8,  1},
 {-0.1,  0.8,  -1}
}

v = cannonv
cannon = {
 { v[5], v[7], v[3], v[1] },--back
 { v[1], v[2]},--left
 { v[4], v[3] },--left
 { v[8], v[7]},--right
 { v[5], v[6] },--right
 { v[8], v[4], v[2], v[6] }--front
}


--default cube
cubev = {
 { 1,  1,  1},--1 btl
 { 1,  1, -1},--2 ftl
 { 1, -1,  1},--3 bbl
 { 1, -1, -1},--4 fbl
 {-1,  1,  1},--5 btr
 {-1,  1, -1},--6 ftr
 {-1, -1,  1},--7 bbr
 {-1, -1, -1}--8 fbr
}

v = cubev
cube = {
 { v[5], v[7], v[3], v[1] },--back
 { v[1], v[2]},--left
 { v[4], v[3]},--left
 { v[8], v[7]},--right
 { v[5], v[6]},--right
 { v[8], v[4], v[2], v[6] }--front
}

--pyramid
pyv = {
 { 0,  2,  0},--1 ftl
 { 1, -1,  1},--2 bbl
 { 1, -1, -1},--3 fbl
 {-1, -1,  1},--4 bbr
 {-1, -1, -1}--5 fbr
}

v = pyv
pyramid = {
 { v[2], v[3], v[5], v[4]}, --bottom
 { v[1], v[2]},
 { v[1], v[3]},
 { v[1], v[4]},
 { v[1], v[5]}
}


--fragment
fragmentv = {
 --x   y   z
-- lr  ud  fb
 {-0.2,  0.2,  0.1},--1 
 { 0.2,  0.4,  0.2},--2 
 { 0.4, -0.1,  0.2},--3 
 {-0.2, -0.2,  0.8},--4 
}

v = fragmentv

fragment = { 
 { v[1], v[2], v[4]},
 { v[1], v[3]},
 { v[4], v[3]},
 { v[2], v[3] },
}


--drill
drillv = {
 --x   y   z
 --bottom tracks
 nil,--1 unused
 { 1, -1,  1},--2 bbl
 { 1, -1, -1},--3 fbl
 {-1, -1,  1},--4 bbr
 {-1, -1, -1},--5 fbr
 --drill head
 { 0.8,  1,  1},--6
 { 1.1,  0.4,  1},--7
 { 0.7,  -0.2,  1},--8
 { 0,  -0.5,  1},--9 mid
 { -0.7, -0.2,  1},--10
 { -1.1, 0.4,  1},--11
 { -0.8, 1,  1},--12
 { 0,  1.4,  1},--13 top
 { 0,  0.6,  -2},--14 tip
 }

v = drillv

drill = {
 --bottom track
 { v[3], v[5] },--front
 { v[2], v[4] },--front
 { v[10], v[4], v[5] },--right
 { v[8], v[2], v[3] },--right
 --head
 { v[6], v[7], v[8], v[9], v[10], v[11], v[12], v[13] }, --outer rim
 { v[6], v[14] },
 { v[7], v[14] },
 { v[8], v[14] },
 { v[9], v[14] },
 { v[10], v[14] },
 { v[11], v[14] },
 { v[12], v[14] },
 { v[13], v[14] },
}
-->8
--entities

function up_entities()
	enemy=false
	for e in all(entities) do
	 e.ang = rollover(e.ang)
  e.tmr+=1
	 if e.t=="tank" then
	  up_enemy(e)
	  getradar(e)
	  
	 elseif e.t=="supertank" then
	  up_supertank(e)
	  getradar(e)
	  
	 elseif e.t=="drill" then
	  up_drill(e)
	  getradar(e)

	 elseif e.t=="ufo" then
	  up_ufo(e)
	  
 	elseif e.t=="player" then
 	 toup = e

  elseif e.t=="cube" then
   if(inrenderdis(e))	drawthing(cube,e.vec3,e.ang)

  elseif e.t=="pyramid" then
  	if(inrenderdis(e))	drawthing(pyramid,e.vec3,e.ang)
  
  elseif e.t=="explosion" then
  	if(inrenderdis(e))	drawthing(dot,e.vec3,0)
  	if(e.l == nil) e.l=rnd(0.5)-0.25 e.r=rnd(0.5)-0.25 e.a=rnd(0.25)
  	e.vec3[1]+=e.l
  	e.vec3[3]+=e.r
  	--bounce
  	e.vec3[2]+=e.a
  	e.a-=0.005
  	if(e.vec3[2]<-0.5)e.a = e.a*-0.8
   if(rnd(e.m)<1) del(entities,e)
  
  elseif e.t=="fragment" then
	  enemy = true
  	if(inrenderdis(e))	drawthing(fragment,e.vec3,e.ang)
  	if(e.l == nil) e.l=rnd(0.5)-0.25 e.r=rnd(0.5)-0.25 e.a=rnd(0.25)
  	e.vec3[1]+=e.l
  	e.vec3[3]+=e.r
  	e.vec3[2]+=e.a
  	e.a-=0.01
  	if(e.vec3[2]<-0.5) del(entities,e)

  elseif e.t=="part" then
	  enemy = true
  	if(inrenderdis(e))	drawthing(turret,e.vec3,e.ang)
  	if(e.l == nil) e.l=rnd(0.1)-0.05 e.r=rnd(0.1)-0.05 e.a=rnd(0.4)
  	e.vec3[1]+=e.l
  	e.vec3[3]+=e.r
  	e.vec3[2]+=e.a
  	e.a-=0.01
  	e.ang+=0.01
  	if(e.vec3[2]<-0.5) del(entities,e)
  end	end
 spawn∧()
	
	--bullets
 for e in all(bullets) do
  e.tmr+=1
  if(e.tmr>60) del(bullets,e)
  if e.t=="bullet" or e.t=="ebullet" then
   e.vec3=move(e.vec3,e.ang,1)
  	drawthing(bullet,e.vec3,e.ang)
   if checkcollisions(e,0) then
    e.tmr = 60
    explode(e,3,4,0.1)
   end
 	end
 end
 if(toup!=nil) up_player(toup)
end

function fire(type,vec3,ang)
	e = {}
	e.vec3 = vec3
	e.ang = ang
	e.t = type
	e.tmr = 0
	e.size = 0.2
 add(bullets,e)
end

function addent(type,vec3,ang,m)
	e = {}
	e.rld = 100
 if(vec3 == nil) vec3 = {0,0,0}
	e.vec3 = vec3
 if(ang == nil) ang = 0
	e.ang = ang
	e.t = type
	e.m = m
	e.tr = 0
	e.tmr = 0
 e.fa = 0
 e.size = 1.2
 if(type=="pyramid") e.size = 0.8
 if(type=="supertank") e.size = 0.9
 if(type=="ufo") e.size = 0.6
 add(entities,e)
end

--bumping object
function checkcollisions(e,spd)
 for o in all(entities) do
  if o!=e and o.t!="explosion" then
   if collide(move(e.vec3,e.ang,spd),o.vec3,e.size,o.size) then
    return true
   end
  end
 end
 return false
end

--hit by bullet
function checkhits(e)
 for o in all(bullets) do
  if (e.t=="tank" or e.t=="drill" or e.t=="supertank" or e.t=="ufo") and o.t=="bullet" then
   if collide(e.vec3,o.vec3,e.size,o.size) then
    del(bullets,o)
    return true
   end

  elseif e.t=="player" and o.t=="ebullet" then
   if collide(e.vec3,o.vec3,e.size,o.size) then
    del(bullets,o)
    sfx(9)
    return true
   end
  end
 end
 for o in all(entities) do
  if e.t=="player" and o.t=="drill" then
   if collide(e.vec3,o.vec3,e.size,1) then
    del(entities, o)
    sfx(9)
    return true
   end
  end
 end
 return false
end

--detect collisions
function collide(vec3,vec32,r,r2)
 if (r == nil) r = 1
 if (r2 == nil) r2 = 1
 if vec3[1]-r < vec32[1]+r2 and
    vec3[1]+r > vec32[1]-r2 and
    vec3[3]-r < vec32[3]+r2 and
    vec3[3]+r > vec32[3]-r2 then
  return true
 end
 return false
end

function inrenderdis(e, opdis)
 if (opdis == nil) opdis = renderdist
 if abs(e.vec3[1]+campos[1]) + 
    abs(e.vec3[3]+campos[3]) <= opdis then
  return true
 end
 return false
end


--shoot toward something
function atangle(tvec,svec)
 targetx=tvec[1]*-1
 targetz=tvec[3]
 startx=svec[1]*-1
 startz=svec[3]
 angle=atan2(targetx-startx,targetz-startz)
 return angle
end

function explode(e,size,dist,rndr)
 if(size==nil) size=20
 if(dist==nil) dist=30
 if(rndr==nil) rndr=1
 for x=1, size do
  nv3 = {}
  nv3[1] = e.vec3[1] + rnd(rndr)-rndr/2
  nv3[2] = e.vec3[2] + rnd(rndr)
  nv3[3] = e.vec3[3] + rnd(rndr)-rndr/2
  addent("explosion",nv3,0,dist)
 end
 for x=1, size/3 do
  nv3 = {}
  nv3[1] = e.vec3[1] + rnd(rndr)-rndr/2
  nv3[2] = e.vec3[2] + rnd(rndr)
  nv3[3] = e.vec3[3] + rnd(rndr)-rndr/2
  addent("fragment",nv3,rnd(1),dist)
 end
end
-->8
--enemy scripts

--ufo
function up_ufo(e)
 if e.tmr>0 then --choose random action
  e.tmr = rnd(40)-50
  e.d = flr(rnd(3))
 end
 if e.d == 0 then
  e.ang -= 0.002
 elseif e.d == 1 then
  e.ang += 0.002
 elseif e.d == 2 then --move forward
  --collision detection
  local go = true
  e.spd = 0.4
  if(checkcollisions(e,e.spd)) go=false
  if go then 
   e.vec3 = move(e.vec3,e.ang,e.spd)
  else --back up
   e.d = 5
   e.tmr =- 15
  end
 elseif e.d == 3 then --back up
  --collision detection
  local go=true
  if(checkcollisions(e,-0.2)) go=false
  if(go) e.vec3=move(e.vec3,e.ang,-0.2)
 end
	drawthing(ufo,e.vec3,e.ang)
 if checkhits(e) then
  score += 500
  del(entities,e)
  explode(e,20)
 end
 if(inrenderdis(e,100)==false)  del(entities,e)
end


--supertank
function up_supertank(e)
 if(e.rld>0 and hit == 0) e.rld -= mid(0.5,difficulty/100,10)
 if e.tmr>0 then --choose random action
  e.tmr = rnd(20)-30
  e.d = flr(rnd(4+difficulty/3))
  if(e.d>3) e.d = 3
  if(inrenderdis(e, 20) and gamemode != 3) e.d = 3
 end
 if e.d == 0 then
  e.ang -= 0.006
 elseif e.d == 1 then
  e.ang += 0.006
 elseif e.d == 2 then --move forward
  --collision detection
  local go = true
  e.spd = 0.6
  if(checkcollisions(e,e.spd)) go=false
  if go then 
   e.vec3 = move(e.vec3,e.ang,e.spd)
  else --back up
   e.d = 5
   e.tmr =- 10
  end
 elseif e.d == 3 then --aim
  --rotation code
  pang = atangle(pvec,e.vec3)-0.25
  if pang+0.002<e.ang then
   if e.ang>0.75 and pang<0.25 then
    e.ang += 0.006
   else
    e.ang -= 0.006
   end
  elseif pang-0.002>e.ang then
   if e.ang<0.25 and pang>0.75 then
    e.ang -= 0.006
   else
    e.ang += 0.006
   end
  end
  if(flr(e.ang*100)==flr(pang*100) and e.rld<1) e.d=4
 elseif e.d == 4 then --fire
  e.tmr = 0
  if(gamemode != 3) sfx(11) fire("ebullet",move(e.vec3,e.ang,1,-0.5),e.ang)
  e.rld = 150-mid(0,difficulty*2,50)
  e.d = 2
  e.tmr = -10
 elseif e.d == 5 then --back up
  --collision detection
  local go=true
  if(checkcollisions(e,-0.3)) go=false
  if(go) e.vec3=move(e.vec3,e.ang,-0.3)
 end
	drawthing(supertank,e.vec3,e.ang)
	drawthing(cannon,move(e.vec3,0,0,-0.6),e.ang+0.5)
 if checkhits(e) then
  score += 400
  sfx(12)
  del(entities,e)
  explode(e,15)
 end
end

--normal tank
function up_enemy(e)
 if(e.rld>0 and hit == 0) e.rld -= 1
 if e.tmr>0 then --choose random action
  e.tmr = rnd(40)-50
  e.d = flr(rnd(4+difficulty/5))
  if(e.d>3) e.d = 3
  if(inrenderdis(e, 10) and gamemode != 3) e.d = 3
 end
 if e.d == 0 then
  e.ang -= 0.004
 elseif e.d == 1 then
  e.ang += 0.004
 elseif e.d == 2 then --move forward
  --collision detection
  local go = true
  e.spd = 0.4
  if(checkcollisions(e,e.spd)) go=false
  if go then 
   e.vec3 = move(e.vec3,e.ang,e.spd)
  else --back up
   e.d = 5
   e.tmr =- 15
  end
 elseif e.d == 3 then --aim
  --rotation code
  pang = atangle(pvec,e.vec3)-0.25
  if pang+0.002<e.ang then
   if e.ang>0.75 and pang<0.25 then
    e.ang += 0.004
   else
    e.ang -= 0.004
   end
  elseif pang-0.002>e.ang then
   if e.ang<0.25 and pang>0.75 then
    e.ang -= 0.004
   else
    e.ang += 0.004
   end
  end
  if(flr(e.ang*100)==flr(pang*100) and e.rld<1) e.d=4
 elseif e.d == 4 then --fire
  e.tmr = 0
  if(gamemode != 3) sfx(11) fire("ebullet",move(e.vec3,e.ang,1,-0.5),e.ang)
  e.rld = 150-mid(0,difficulty*2,50)
  e.d = 2
  e.tmr = -10
 elseif e.d == 5 then --back up
  --collision detection
  local go=true
  if(checkcollisions(e,-0.2)) go=false
  if(go) e.vec3=move(e.vec3,e.ang,-0.2)
 end
	drawthing(tank,move(e.vec3,e.ang,0.5,-0.5),e.ang)
	drawthing(cannon,move(e.vec3,e.ang,0.5,-0.5),e.ang)
	if(e.dang == nil) e.dang = 0
	e.dang+=0.02
	drawthing(dish,move(e.vec3,e.ang,-1,0.3),e.dang)
 if checkhits(e) then
  score += 200
  sfx(12)
  del(entities,e)
  explode(e,20)
 end
end


--those drill missle things
function up_drill(e)
 e.rld += 1
 go = true
 if checkhits(e) then
  score += 500
  sfx(12,2)
  del(entities,e)
  explode(e,15)
 else
	
	 if(hit>0) del(entities, e) sfx(-1,2)
	 if e.vec3[2]>0 then --drop
	  e.vec3[2]-=0.5
	  e.rld = 0
	  e.tang = atangle(pvec,e.vec3)-0.25
	 elseif e.rld < 20 then --left
	  e.ang = e.tang+0.15
	 elseif e.rld < 40 then --right
	  e.ang = e.tang-0.15
	 elseif e.rld < 60 then --left
	  e.ang = e.tang+0.15
	 elseif e.rld < 80 then --right
	  e.ang = e.tang-0.15
	 elseif e.rld < 300 then --charge!
	  e.ang = e.tang
	 else
	  del(entities,e)
	  sfx(14,2)
	 end
	 if(checkcollisions(e,0)) go = false
	 if go then 
	  e.spd = 1
	  e.vec3 = move(e.vec3,e.ang,e.spd)
	 else --explode
	  del(entities,e)
	  explode(e,15)
	  sfx(14,2)
	 end
		drawthing(drill,e.vec3,e.ang)
	end
end

--fixing this, all targets will now
--add coordinates to a table for the radar x and y
function getradar(e)
 enemy = true --used for spawning new waves
 
 --target on radar
 tang = theta-atangle(e.vec3,pvec)
 tang = rollover(tang)-0.01
 t_rng = sqrt((e.vec3[1]-pvec[1])^2+
              (e.vec3[3]-pvec[3])^2)
 local contact={ang = tang, --angle
                rng = mid(1,8,t_rng/10)}--range
 add(radar_tgt,contact)
 --check if in sights
 floored = flr(tang*40)
 if(floored > 8 and floored < 11) insight = true
end
-->8
--spawn waves

function spawn∧()
 if enemy == false and update == up_entities then
  --ufos
  if rnd(10)<1 then
   rndvec = {rnd(80)-40,0,rnd(80)-40}
   if inrenderdis({vec3=rndvec},10)==false then
  	 addent("ufo",rndvec)
  	end
  end
 
  if rnd(4)<1 and gamemode != 3 then
 	 rndvec = {rnd(120)-60,20,rnd(120)-60}
 	 if inrenderdis({vec3=rndvec},100)==false then

  	 addent("drill",rndvec)
  	 sfx(13,2)
  	 sfx(10)
  	end

  elseif rnd(2)<1 and difficulty>10 then
   if(gamemode == 1) howmany = 1
   if(gamemode == 2) howmany = 3
   for i=1, howmany do --how many
  	 rndvec = {rnd(80)-40,0,rnd(80)-40}
  	 if checkcollisions({vec3=rndvec},0) == false and
  	    inrenderdis({vec3=rndvec},70)==false then
   	 addent("supertank",rndvec)
   	 sfx(10)
   	end
   end
  else --tank
   if(gamemode == 1) howmany = 1
   if(gamemode == 2) howmany = 2
   if(gamemode == 3) howmany = 3
   for i=1, howmany do --how many
  	 rndvec = {rnd(60)-30,0,rnd(60)-30}
  	 if checkcollisions({vec3=rndvec},0) == false and
  	    inrenderdis({vec3=rndvec},20)==false then
   	 addent("tank",rndvec)
   	 sfx(10)
   	end
   end
  end
  difficulty+=1
 --random drills
 elseif gamemode == 2 and rnd(200)<1 then
	 rndvec = {rnd(150)-75,20,rnd(150)-75}
	 if inrenderdis({vec3=rndvec},100)==false then
 	 addent("drill",rndvec)
   sfx(10)
 	end
 end
end
-->8
--background and font

--thanks kirschner!

--custom font example
--by sophie kirschner
--sophiek@pineapplemachine.com
--zlib/libpng license
--http://opensource.org/licenses/zlib

function text(x,y,str)
    for i=1,#str do
        char=sub(str,i,i)
        spr(charmap[char],x,y)
        x+=charwidth[char]
    end
end

--background by phin
function init_bg()
 hor2 = 65
 horizon = hor2 + camera_y
 ang = 0
 radius=0
 hwidth = 0
 particles = {}
 --format height right
 bkgnd = {"15 15",
          "00 -5",--extra line
          "15 5",
          "10 20",
          "7 20",
          "20 00",--building
          "18 03",--roof
          "7 00",
          "10 10",
          "05 30",
          "25 7",--volcano
          "22 1",
          "24 1",
          "22 1",
          "24 1",--lava
          "25 1",--volcano
          "0 10",
          "15 8",
          "0 2",
          "15 -2",
          "0 25",
          "0 100",
          "15 2",
          "17 5",
          "0 1",
          "17 -1",
          "0 15",
          "20 15",
          "0 2",
          "20 -2",
          "8 20",
          "0 -12",
          "16 24",
          "0 5",
          "12 10",
          "0 8",
          "12 -8",
          "0 14",
          "0 80",
          "20 0",
          "20 5",
          "0 0",
          "12 0",
          "12 3",
          "14 2",
          "12 -2",
          "12 4",
          "8 0",
          "8 -3",
          "0 0",
          "8 0",
          "8 10",
          "0 0",
          "0 2",
          "20 0",
          "23 3",
          "20 3",
          "0 0",
          "15 0",
          "15 5",
          "0 0",--end of city
          "0 10",
          "12 7",
          "0 -1",
          "12 1",
          "3 12",
          "18 4",
          "5 5",
          "0 0",
          "5 0",
          "18 -5",
          "0 18",
          "12 8",
          "4 0",
          "0 5",
          "28 19",
          "0 8",
          "28 -8",
          "0 23",
          "30 38",--mt fat
          "23 -5",
          "0 -12",
          "23 12",
          "30 5",
          "5 35",
          "0 -6",
          "15 18",
          "0 8",
          "5 0",
          "5 2",
          "",
          "0 0"}
 bkx={}
 bky={}
 for cntr=1, #bkgnd do
  vert = bkgnd[cntr]
  for spoint = 2, #vert do
   if sub(vert, spoint, spoint) == " " then
    y = sub(vert, 1, spoint-1)
    x = sub(vert, spoint+1, #vert)
    add(bkx,x)
    add(bky,y)
    hwidth+=x
   end
  end
 end
end


--render background
function rendermap()
 horizon = hor2 + camera_y
 line(0,horizon,127,horizon,3)
 ypos = 0
 xat = -theta*hwidth
 
 for cntr=1, #bkx do
  lasty = ypos
  ypos = bky[cntr]
  xadd = bkx[cntr]
  line(xat, 
       horizon - lasty ,
       xat+xadd,
       horizon - ypos,3)
  xat += xadd
 end
end

function rendermoon()
 circ(14-theta*hwidth,horizon-35,5,3)
 line(13-theta*hwidth,horizon-35,15-theta*hwidth,horizon-30,3)
 line(13-theta*hwidth,horizon-35,15-theta*hwidth,horizon-40,3)
end

function renderparticles()
 --add volcano 
 if flr(rnd(20))<1 then
  volc = {}
  volc.x = 105 + rnd(5)
  volc.y = horizon - 25
  volc.d = rnd(2)-1
  volc.s = rnd(1)
  volc.t = 20
  add(particles, volc)
 end
 
 for p in all(particles) do
  pset(p.x-theta*hwidth, p.y,3)
  p.y -= p.s
  p.x += p.d
  p.t -= 1
  if(p.t==0 or rnd(50)<1) del(particles, p)
 end
end

function update_bg()
 theta-=1
 rendermap()
 rendermoon()
 renderparticles()
 theta+=1
 rendermap()
 rendermoon()
 renderparticles()
 
end
