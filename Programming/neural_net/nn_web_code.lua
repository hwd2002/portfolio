function _init()
-- #include saved_net.txt
 --tweakables
 numofshapes = 20
 sight_rng = 100 --how far tanks see
 borders = 600
 timeout = 600
 score_age = 0.5
 midneurons = 4
 
 init_shapes()
 entities = {}
-- if load_data then
--  local data = load_data()
--  add_tank(0,0,0,data)
-- end

 add_tank(64,-64,1,save_net(generate_nn()))
 add_tank(0,-64,2,save_net(generate_nn()))
 add_tank(-64,-64,3,save_net(generate_nn()))
 add_tank(64,0,4,save_net(generate_nn()))
 add_tank(0,0,11,save_net(generate_nn()))
 add_tank(-64,0,10,save_net(generate_nn()))
 add_tank(64,64,7,save_net(generate_nn()))
 add_tank(0,64,8,save_net(generate_nn()))
 add_tank(-64,64,9,save_net(generate_nn()))
 
 
 global_rnd = 0
 tmr = 0
 measured_speed = 15
 
 post_msg("q to change camera")
 
 speed_on = false
 old_cpu = 0
 camx,camy,cams = 0,0,1
 camtank  = entities[1]
 
 menuitem(1, 'fast fwd', ff_toggle)
 menuitem(2, 'clone tank', clone_tank)
 menuitem(3, 'spawn player', spwn_plr)
 menuitem(4, 'rspwn tank', respawn_tank)
 menuitem(5, 'delete tank', del_tank)
-- menuitem(5, 'write data', write_data)
end

function spwn_plr()
 add_tank(0,0,0)
 camtank  = entities[1]
 post_msg("arrow keys+z+x to move")
end

function post_msg(_str)
 message = 200
 msg_txt = _str
end

function respawn_tank()
 camtank.hp = 0
end

function del_tank()
 del(entities,camtank)
 post_msg("deleted tank")
end

function clone_tank()
 add_tank(0,
          0,
          camtank.col+flr(rnd(8)-4),
          camtank.storednn)
 post_msg("cloned tank")
end

function _update()
 max_speed = 1
 if speed_on then
  max_speed = measured_speed
  if old_cpu<0.9 then
   measured_speed += 1
  elseif tmr%10==0 then
   measured_speed -= 2
  end
	else
	 measured_speed = 1
	end
 for i=1,max_speed do
  tmr+=1
	 global_rnd = sin(tmr/500)
	 up_tanks()
	 up_entities()
	 --respawn shapes
	 if #entities-numoftanks<numofshapes then
	  add_shape(balrnd(128),balrnd(128),flr(rnd(2.5)+1))
	 end
	end
end

function _draw()
 cls(6)
 cam()
 dr_entities()
 camera()
 print("age:"..camtank.age.."\niterations:"..camtank.iterations.."\nchange:"..camtank.randchange.."\nhighscore:"..camtank.highscore.."\nscore:"..camtank.score,1,1,0)
 for i in all(camtank.sight) do
  if i==-1 then
   color(0)
   print(i)
  elseif i>0 then
   color(2)
   print("+"..i)
  else
   color(1)
   print(" "..i)
  end
 end
 old_cpu = cpu
 cpu = stat(1)
 print("mem:"..stat(0)/2048 .."\ncpu:"..cpu.."\nrnd:"..global_rnd.."\nspd:"..measured_speed,87,1,0)
 
 --messages to player
 if message>1 then
  message -= 1
  print(msg_txt,62-#msg_txt*2,120,7)
  print(msg_txt,63-#msg_txt*2,119,7)
  print(msg_txt,64-#msg_txt*2,120,7)
  print(msg_txt,63-#msg_txt*2,121,7)
  print(msg_txt,63-#msg_txt*2,120,0)
 end
end

function cam()
 camx -= (camx-(camtank.x-64))/4
 camy -= (camy-(camtank.y-64))/4

 mdens = 64--density of map grid
 camera(camx%mdens,camy%mdens)
 for x1=0,128+mdens, mdens do
	 for y1=0,128+mdens, mdens do
	  spr(1,x1-3,y1-3)
	 end
 end
 if btnp(🅾️,1) or
    btnp(❎,1) then
 
  camc = 1
  for e in all(entities) do
   if e.tank then
    e.camid = camc
    camc+=1
   end
  end
  cams += 1
  if(cams>numoftanks) cams = 1
  for e in all(entities) do
   if cams==e.camid then
    camtank = e
    break
   end
  end
 end
 camera(camx,camy)
end

function ff_toggle()
  speed_on = not speed_on
end
-->8
--neural net
--[[neuron format:
neuron = 
{ 
 connections = connections table to next layer,
 bias,
 output = stored output
}
]]--

--layers ==>
--depth/neurons per layer \/
function generate_nn(_data)
 local net = {{},{},{}}
 inner_layer = 7
 outer_layer = 3
 --make neurons--
 --inner layer
 for i=1,inner_layer do
  add(net[1],{
       connections = {},
       bias = balrnd(1),
       output = 0
      })
 end
 
 --middle neurons
 for i=1,midneurons do
  add(net[2],{
       connections = {},
       bias = balrnd(1),
       output = 0
      })
 end
 
 --outer layer
 for i=1,outer_layer do
  add(net[3],{
       connections = {},
       bias = balrnd(1),
       output = 0
      })
 end
 
 --connect in>out neurons
 local i=0
 for n in all(net[1]) do
  i+=1
  for n2 in all(net[3]) do
   if n.connections[i] then
    n.connections[i].dest=n2
   else
    add(n.connections,
 	      {dest=n2,
 	       weight = balrnd(4)})
 	 end
	 end
 end
 
 --connect in>mid>out neurons
 for mn in all(net[2]) do
  local i = 0
	 for n in all(net[1]) do
	  i += 1
	  if n.connections[i] then
    n.connections[i].dest=mn
   else
		  add(n.connections,
		      {dest=mn,
		       weight = balrnd(4)})
 	 end
	 end
	 local i = 0
	 for n in all(net[3]) do
	  i += 1
	  if n.connections[i] then
    n.connections[i].dest=mn
   else
 	  add(n.connections,
 	      {dest=mn,
 	       weight = balrnd(4)})
 	 end
	 end
 end
 if(_data!=nil) net = load_net(net,_data)
 return net
end

function run_net(net,inputs)
 
 --reset outputs
 for l=1,3 do
  for n in all(net[l]) do
   n.output = n.bias
  end
 end
 
 --layer 1, process inputs
 for i=1, #inputs do
  net[1][i].output = net[1][i].bias + inputs[i]
 end
 
 --run connections
 for l=1,2 do
  for n in all(net[l]) do
   for c in all(n.connections) do
    c.dest.output += c.weight*n.output
   end
  end
 end
 
 local output = {}
 for neuron=1, #net[3] do
  add(output,net[3][neuron].output)
 end
 return output
end

function save_net(net,string)
 local data = {}
 local str = "function load_data() return split('"
 for layer in all(net) do
  for neuron in all(layer) do
   add(data,tonum(neuron.bias))
   str = str..neuron.bias..","
   for conn in all(neuron.connections) do
    add(data,tonum(conn.weight))
    str = str..conn.weight..","
   end
  end
 end
 str = str.."',',',true) end"
 if(string) return str
 return data
end

function load_net(net,_data)
 data_addr = 0
 for layer in all(net) do
  for neuron in all(layer) do
   neuron.bias = get_data(_data)
   for conn in all(neuron.connections) do
    conn.weight = get_data(_data)
   end
  end
 end
 return net
end

function get_data(_data)
 data_addr += 1
 return _data[data_addr]
end

function randomize_net(_data,adjust)
 for d in all(_data) do
  d = tonum(d)
  if d==nil then
   del(_data,d)
  else
   d = mid(-2,2,d+balrnd(adjust))
  end
 end
 return _data
end

function randomize_neuron(_data)
 d = flr(rnd(#_data)+1)
 _d = tonum(_data[d])
 _d = mid(-2,2,_d*-1+balrnd(1))
 _data[d] = _d
 return _data
end

function write_data()--write to disk
 str = save_net(camtank.nn,true)
 printh(str,"saved_net.txt",true)
end
-->8
--game
function see_fwd(tank)
 --front l, front r, back l, back r
 tank.sight = {-1,-1,-1,-1,-1}
 angles = {-0.4,-0.15,0,0.15,0.4}
 degrees = {0.15,0.1,0.05,0.1,0.15}
 for ent in all(entities) do
  if ent!=tank and
     not ent.bullet then
   tank.a = rollover(tank.a)
   local _xd,_yd = abs(ent.x-tank.x),abs(ent.y-tank.y)
   if _xd<sight_rng and
      _yd<sight_rng then
	   local goal = atan2(ent.x-tank.x,ent.y-tank.y)
	   for i=1,5 do
		   if turn(goal,tank.a+angles[i],degrees[i]) then
		    local rng = 1-mid(-1,1,(_xd+_yd)/sight_rng)
		    if ent.tank then
 		    tank.sight[i]+=rng+0.5
		    else
 		    tank.sight[i]+=rng
 		   end
 		   tank.sight[i] = min(1,tank.sight[i])
		   end
	   end
	  end
  end
 end
end

function up_tanks()
 numoftanks = 0
 for tank in all(entities) do
	 if tank.tank then--is a tank
	  see_fwd(tank)
		 tank.age += 1
		 tank.rld-=1
   numoftanks += 1
   if tank.hp<50 then
    tank.hp+=0.1
    if tank.regen>0 then
     tank.regen-=1
     tank.hp+=1
    end
   end
	  if tank.player then
	   if(btn(⬆️)) tank.yi-=1
	   if(btn(⬇️)) tank.yi+=1
	   if(btn(⬅️)) tank.xi-=1
	   if(btn(➡️)) tank.xi+=1
	   if(btn(❎)) tank.a-=0.02
	   if(btn(🅾️)) tank.a+=0.02
	   
	  else--run neural net
 		 if(tank.age>timeout) tank.hitby=nil tank.hp = 0
	   local inputs = 
	       {tank.sight[1],
	        tank.sight[2],
         tank.sight[3],
         tank.sight[4],
         tank.hp/12-1,
         global_rnd
        }
	   
	   cont = run_net(tank.nn,inputs)
	   
	   if(cont[1]>0.8) tank.a-=0.02
	   if(cont[1]<0.2) tank.a+=0.02
	   if cont[2]>0.7 then
	    tank.xi+=cos(tank.a)
	    tank.yi+=sin(tank.a)
	   elseif cont[2]<0.3 then
	    tank.xi-=cos(tank.a)
	    tank.yi-=sin(tank.a)
	   end
	   --strafe
	   if cont[3]>0.8 then
	    tank.xi+=cos(tank.a+0.25)/2
	    tank.yi+=sin(tank.a+0.25)/2
	   end
	   if cont[3]<0.2 then
	    tank.xi+=cos(tank.a-0.25)/2
	    tank.yi+=sin(tank.a-0.25)/2
	   end
	   tank.xi = mid(-3,3,tank.xi)
	   tank.yi = mid(-3,3,tank.yi)
	  end
   fire(tank)
	 end
 end
end

function up_entities()
 for ent in all(entities) do
	  --bump other objects
	  for t2 in all(entities) do
	   if t2!=ent and
	      hbo(ent,t2) then
			  local cdir = atan2(ent.x-t2.x,ent.y-t2.y)
			  local ccos,csin = cos(cdir)/4,sin(cdir)/4
			  t2.xi = ccos*-1
			  t2.yi = csin*-1
			  ent.xi = ccos
			  ent.yi = csin
		   t2.hp -= 1
		   ent.hp -= 1
		   --bullet hits something
		   if ent.bullet and 
		      not t2.bullet then
		    ent.hitby = nil
		    t2.hitby = ent.owner
		    ent.owner.score+=1
		    t2.hp -= 4
		   else
		    ent.hitby = t2
		    t2.hitby = ent
		   end
			 end
	  end
  ent.x+=ent.xi
  ent.y+=ent.yi
  if not ent.bullet then
   ent.xi*=0.5
   ent.yi*=0.5
   ent.x = mid(borders*-1,borders,ent.x)
   ent.y = mid(borders*-1,borders,ent.y)
  else
   ent.hp -= 1
   if abs(ent.xi)+abs(ent.yi)<0.5 then
    ent.hp = 0
   end
  end
  if ent.hp<1 then
   if ent.hitby then
    ent.hitby.score += ent.scoreval
    ent.hitby.age = 0
    if(ent.tank)ent.hitby.regen=25
   end
   if ent.nn then
    reincarnate(ent)
   end
   del(entities,ent)
  end
 end
end

function dr_entities()
 local radius = 5
 for entity in all(entities) do
  tx,ty = entity.x,entity.y
  if entity.tank then
	  local acos,asin = cos(entity.a),sin(entity.a)
	  radius+=2
	  rspr(0,
	       tx+acos*radius,
	       ty+asin*radius,
	       entity.a)
	  radius-=2
	  drawcirc(entity.col,radius)
   hp_bar(tx,ty,entity.hp/2)
	 elseif entity.bullet then
	  drawcirc(entity.col,2)
	 else
	  rspr(entity.spr,
	       tx,
	       ty,
	       entity.a,
	       entity.mult)
	  entity.a+=0.001
	 end
 end
end

function drawcirc(col,radius)
 circfill(tx,
          ty,
          radius,
          col)
 circ(tx,
      ty,
      radius,
      5)

end
-->8
--utility funcs

function balrnd(x)
 return rnd(x*2)-x
end

function sigmoid(x)
 return 1/(1+(-x)^2)
end

function hbo(t1,t2)--hitbox over?
 local dx = t2.x-t1.x
 local dy = t2.y-t1.y
 local chs = t1.hbr+t2.hbr
 if abs(dx)<chs and
    abs(dy)<chs then
  if sqrt(dx^2+dy^2)<chs then
   return true
  end
 end
 return false
end

function hp_bar(_x,_y,_p)
 _x-=8
 _y+=10
 local _x2 = _x+16
 local _y2 = _y--now just a line
 rectfill(_x,_y,_x2,_y2,1)
 if _p>0 then
  rectfill(_x,_y,_x+max(0,_p*0.64+1),_y2,8)
 end
end

function rspr(s,x,y,a,mult)
 if abs(x-camx-8)>128 or
    abs(y-camy-8)>128 then
  return
 end
 if(mult==nil) mult = 1
 mult = mult*4
 if speed_on and s!=0 then
  --no rotation
  spr(s,x-mult,y-mult,mult/4,mult/4)
 else
	 a = 1-a
	 local _a2 = flr(a*32+0.5)/32
	 local ca,sa = cos(_a2),sin(_a2)
	 --spritesheet coords
	 local sx = 8*(s%16)+mult
	 local sy = flr(s/16)*8+mult
	
	 for xc=-mult,mult do
	  for yc=-mult,mult do
	   xcal = xc*ca - yc*sa + 0.5
	   ycal = yc*ca + xc*sa + 0.5
	   if mid(-mult,mult-0.02,xcal)==xcal and
	      mid(-mult,mult-0.02,ycal)==ycal then
	    p = sget(sx+xcal,
	             sy+ycal)
	    if p!=0 then
	     pset(x+xc,
	          y+yc,
	          p)
	    end
	   end
	  end
	 end
	end
end

function rollover(ang)
 return ang - flr(ang)
end

function turn(goal,current,speed)
 if current-goal>.5 then
  goal += 1
 elseif goal-current>0.5 then
  goal -= 1
 end
 if goal>current+speed then
  return false
  
 elseif goal<current-speed then
  return false
 end
 return true
end

-->8
--spawning

function init_shapes()
 --spr,hp,size
 shapes =
 {{16,12,4,8},
  {17,5,4,5},
  {18,25,6,15},
 }
end

--reincarnate an instance of a tank
function reincarnate(ent)
 local newnn = ent.storednn
 randchange = 0.02
 if ent.score>ent.highscore then
  newnn = save_net(ent.nn)
  ent.storednn = save_net(ent.nn)
 else
  if ent.score<10 then
   --reduce highscore
   ent.highscore -= score_age
   if ent.highscore<1 then
    randchange = 4
   end
  elseif rnd()<0.5 then
	  randchange = 0.1
	 
	 end
	 if rnd()<0.5 then
   newnn = randomize_net(newnn,randchange)
  else
   randchange = "single"
   newnn = randomize_neuron(newnn)
  end
 end
 
 add_tank(balrnd(borders/2),balrnd(borders/2),ent.col,newnn)
 
 entities[1].iterations = ent.iterations+1
 entities[1].highscore = ent.highscore
 if ent.highscore<ent.score then
  entities[1].highscore = ent.score
  entities[1].storednn  = ent.storednn--override newer nn with old
 end
 entities[1].randchange = randchange
 if camtank==ent then
  camtank = entities[1]
 end
end

function fire(tank)
 if tank.rld<1 then
	 local bullet = base_tbl(tank.x,
	                         tank.y,
	                         15,
	                         2,
	                         tank.a)
	 xm,ym = cos(tank.a)*5,sin(tank.a)*5
	 bullet.xi = xm
	 bullet.yi = ym
	 bullet.scoreval = 0
	 bullet.x += xm*3
	 bullet.y += ym*3
	 bullet.col = tank.col
	 bullet.bullet = true
	 bullet.owner = tank
	 tank.xi -= xm/3
	 tank.yi -= ym/3
	 add(entities,bullet)
	 tank.rld = 10
	end
end

function base_tbl(_x,_y,_hp,_hbr,a)
 local tbl = {x = _x,
						        y = _y,
						        regen = 0,
						        xi = 0,
						        yi = 0,
						        a = rnd(), --angle
						        hp = _hp,
						        hbr = _hbr,
						        scoreval = 0,
						        score = 0,
						        highscore = 0
 }
 return tbl
end

function add_shape(_x,_y,_t)
 shape = base_tbl(_x,_y,shapes[_t][2],shapes[_t][3],rnd())
	shape.shape = true
	shape.spr = shapes[_t][1]
	shape.scoreval = shapes[_t][4]
	if shape.spr==18 then
	 shape.mult = 2
	end
 add(entities,shape)
end

function add_tank(_x,_y,_c,_data)
 tank = base_tbl(_x,_y,50,5,0)
 tank.col = _c --color
 tank.rld = 0 --reload for gun
 tank.tank = true
 tank.age = 0
 tank.scoreval = 25
 tank.iterations = 1
 tank.randchange = 0
 if _data then--ai
  tank.nn = generate_nn(_data)
  tank.storednn = _data
 else--player
  tank.player = true
 end
 add(entities,tank,1)
end
