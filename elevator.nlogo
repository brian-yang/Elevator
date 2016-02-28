turtles-own [
  speed               ; speed of the turtle
  in-elevator?        ; determines whether a turtle is in the elevator or not
  start-time          ; at what time did the turtle start waiting at the elevator doors?
  end-time            ; at what time did the turtle reach the floor that it wanted to go to
]

globals [
  elevator-absolute-position ; determines where exactly the elevator is (used as a counter)
  elevator-floor-position    ; the floor that the elevator is currently on
  elevator-floor-going       ; the floor that the elevator is going to
  elevator-queue             ; list of all the floors that the elevator has to go to
  reached-a-floor?           ; is the elevator at a floor and not moving in between floors?
  going-up?                  ; which direction will the elevator take to get to the next floor?
]

;-------------------------------------------------------------------------------------------
to setup
  ca

  resize-world -28 28 -28 28
  
  
  ;; BUILDING SETUP ;;
  
  ask patches with [pxcor >= -18 and  pxcor <= 28]; colors an area of patches red
  [set pcolor red]
  
  ;creates several strips of blue patches from the region of red patches
  
  ask patches with [pcolor = red and pycor mod 7 >= 1 and pycor mod 7 <= 3]  
  [set pcolor blue
    if (pycor mod 7 = 2 and pxcor = max-pxcor)
      [spawn-turtles]]   ; spawns turtles at the floor entrances to the far right of the map
  
  ;creates the floor walls, the ceilings, and the doors on each floor
  ;from the strips of patches
  
  ask patches with [pxcor > -18 and pxcor < 28 and pycor mod 7 != 0]
  [set pcolor turquoise]
  
  
  
  ;; ELEVATOR SETUP ;;
  
  ask patches with [pcolor = black and pycor <= -21]; actual elevator
  [set pcolor grey]
  
  ask patches with [pxcor = -28]; elevator pole 
  [set pcolor yellow]
  
  ask patches with [pycor = -28 and pxcor >= -27 and pxcor <= -19]; elevator base
  [set pcolor green]
  
  ask patches with [pxcor = -16 and pycor mod 7 = 3]; elevator button
  [set pcolor pink
  set plabel round (pycor / 7) + 5]  
   
  ; initializing elevator variables  
  
  set elevator-absolute-position 7  
  set elevator-floor-position 1   
  set elevator-floor-going 0     
  set elevator-queue []          
  set reached-a-floor? true  
  set going-up? true    
 
 
  
  ; the timer will determine the time it took for a turtle to get from the elevator door to another 
  ; floor
  
  reset-timer
  
  
end

;-------------------------------------------------------------------------------------------
to spawn-turtles ; creates the turtles
  
  sprout random (Max-Num-People-Per-Floor + 1) ; spawns a random number of people per floor
  
  [ set size 2.5 
    set shape "person business" ; imported from the turtle models editor
    set heading 270
    set color random 140
    setxy pxcor - 0.5 pycor - 0.2 ; makes the turtles look like they're on the ground          
    
    ; initializing turtle variables
    
    set speed random-float 1 + 1 
    set in-elevator? false 
    set start-time 0  
    set end-time 0 ] 
  
end


to infinite-spawn ; keeps on spawning turtles at the floor entrances, located to the far right
  
 every (random 3 + 5) 
 [ ask patches with [pycor mod 7 = 2 and pxcor = max-pxcor] ;
      [spawn-turtles]  ]
 
end

;-------------------------------------------------------------------------------------------
to go 


every 0.05 [
      
    set elevator-queue sort elevator-queue ; sorts the list of floors that the elevator goes to
    
    ; prevents the elevator from going to the same floor twice in a row
    set elevator-queue remove-duplicates elevator-queue 
     
     
    
    ;TURTLES IN THE BUILDING
    
    ask turtles [
      
      if [pcolor] of patch-here != grey  ; checks if person is in the building, not the elevator       
        [walk-to-elevator]     ; else, keep walking to the elevator
        
      if heading = 90  ; if a turtle just got off the elevator 
        [walk-out]    ; walk to the floor entrance and leave the floor    
        
    ] ;;end of ask turtles   
    
     
   
   if reached-a-floor? = true [
     
     ask turtles with [pycor mod 7 = 2 and pxcor = -18 and [pcolor] of patch-ahead 1 = grey] 
      [get-in]  ; get in the elevator if you are at the elevator door 
      
     ask turtles with [label = elevator-floor-position] ; if this is the floor you get off at
      [get-out]  ; get out of the elevator
      
    ] ;;end of reached-a-floor? if statement
   
]
    
    
every 0.02 [   
  
    ;MANAGES ELEVATOR MOVEMENT & TURTLES IN ELEVATOR USING THE QUEUE   
     
     
  if any? patches with [pcolor = magenta] or any? turtles with [in-elevator? = true] [
      
     
      ; if the floor the elevator has to go to next is the same floor that the elevator is on,
      ; then ignore this floor and go to the floor that is next on the list
      
    if elevator-floor-position = first elevator-queue  
      [set elevator-queue remove first elevator-queue elevator-queue] 


    if not empty? elevator-queue [
               
      ; if the elevator is on the lowest floor or there are no lower floors to go to
      ; then the next floor the elevator will go to will be higher than the current floor
      
      if elevator-floor-position = 1 or empty? filter [? < elevator-floor-position] elevator-queue
        [set going-up? true]
      
      
      ; if the elevator is on the highest floor or there are no higher floors to go to
      ; then the next floor the elevator will go to will be lower than the current floor  
              
      if elevator-floor-position = 8 or empty? filter [? > elevator-floor-position] elevator-queue
        [set going-up? false] 
      
      
      ; this is where the floor that the elevator is going to will be set    
      
      ifelse going-up? = true
        [set elevator-floor-going first filter [? > elevator-floor-position] elevator-queue]
        [set elevator-floor-going first filter [? < elevator-floor-position] elevator-queue]
         
      ] ;; end of elevator-queue if statement
    
          
      move-elevator ; moves the elevator (part of elevator movement if statement)
      
   ] ;; end of elevator movement if statement 
    
]


end

;-------------------------------------------------------------------------------------------
;; TURTLE/PEOPLE MOVEMENT ;;

to walk-to-elevator
  ifelse pxcor - 3 < -18 and heading != 90 ; if you are CLOSE TO and GOING TOWARDS
                                         ; the elevator door, move there instantly 
    [ set speed 0                       
      set xcor -18
      if start-time = 0 [set start-time timer] ; sets the time that a turtle starts waiting
      ask patch -16 (pycor + 1) 
        [if pcolor != magenta 
          [set pcolor magenta  ; calls the elevator when a turtle is at the elevator door
           set elevator-queue lput plabel elevator-queue ]]  ] ; add the floor you're on to queue
    
    [fd speed] ; else, keep moving to the elevator doors
    
end


to get-in   ; gets turtles into the elevator
  
  if count turtles-on patches with [pcolor = grey] < elevator-capacity ; ELEVATOR CAPACITY
  [ 
    move-to min-one-of patches with [pcolor = grey] [pycor] 
    set ycor pycor + 1   ; makes it look like the turtles are on the elevator
    
    ; moves the turtles to the least crowded spot in the elevator
    move-to one-of patches with [pcolor = grey and pycor = [pycor] of myself] with-min [count turtles-here] 
    
    set label random 8 + 1    
    ; if the floor you choose to go to is the floor you are on, then pick another floor
    while [label = elevator-floor-position]  
       [set label random 8 + 1]              
          
    set elevator-queue lput label elevator-queue ; add the floor you choose to the queue
    set in-elevator? true 
    ask patches with [pcolor = magenta] with-min [distance myself] [set pcolor pink]  
  ]

end


to get-out  ; gets turtles out of the elevator
  
   move-to min-one-of patches with [pxcor = -18 and pycor mod 7 = 2] [distance myself]
   if end-time = 0 [set end-time timer] ; sets the time when a turtle gets out
   set in-elevator? false
   set label " "
   set heading 90 
   setxy pxcor - 0.5 pycor - 0.2 ; makes the turtles look like they're on the ground   
   
end


to walk-out   ; moves turtles to the floor entrances
  
  ifelse [pxcor] of patch-ahead 2 = max-pxcor
  [ht
   set speed 0]
  [fd 2]
  
  
end

;-------------------------------------------------------------------------------------------
;; ELEVATOR MOVEMENT ;;


to move-elevator  ; combines both move-elevator-up and move-elevator-down
  
    ifelse elevator-floor-going > elevator-floor-position 
     
    ; if the elevator needs to go to a higher floor, move the elevator up    
             
         [ move-elevator-up
           wait 0.1 
           set elevator-absolute-position elevator-absolute-position + 1 ]
           
    ; if the elevator needs to go to a lower floor, move the elevator down  
              
         [ move-elevator-down
           wait 0.1 
           set elevator-absolute-position elevator-absolute-position - 1 ]  
          
   
   ; every time the absolute position of the elevator can be divided into evenly by 7,
   ; it means that the elevator is at a certain floor and not moving 
    
   set elevator-floor-position elevator-absolute-position / 7      
   
   ifelse elevator-absolute-position mod 7 = 0 
     [set reached-a-floor? true]
     [set reached-a-floor? false]
        
end


to move-elevator-up ; MOVES THE ELEVATOR UP
  
  ; unless the ceiling is hit, the elevator can move higher 
  ask patches with [pcolor = grey] with-min [pycor]  
  [if [pycor] of patch-at-heading-and-distance 0 6 != max-pycor 
    
    ; set the pcolor of lowest row of patches with [pcolor = grey] to black  
    ; set the pcolor of the row directly above the elevator with [pcolor = black] to grey  
    [set pcolor black                
     ask patch-at-heading-and-distance 0 7 [set pcolor grey] ] ]
      
  
  ask turtles with [in-elevator? = true]
    [if pycor != max-pycor - 5 
      [set ycor pycor + 1] ]; turtles move separately from the elevator
    
end



to move-elevator-down   ; MOVES THE ELEVATOR DOWN 
  
  ; unless the ground is hit, the elevator can move lower
  ask patches with [pcolor = grey] with-max [pycor] 
  [if [pycor] of patch-at-heading-and-distance 180 6 != min-pycor + 1   
    
    ; sets the pcolor of highest row of patches with [pcolor = grey] to black  
    ; sets the pcolor of the row directly below the elevator with [pcolor = black] to grey
    [set pcolor black;      
     ask patch-at-heading-and-distance 180 7 [set pcolor grey] ] ]
  
  
  ask turtles with [in-elevator? = true]
    [if pycor != min-pycor + 1
     [set ycor pycor - 1] ] ; turtles move separately from the elevator
  
end

;-------------------------------------------------------------------------------------------
to-report Average-Time
  
report sum [end-time - start-time] of turtles with [end-time > start-time] / 
       count turtles with [end-time > start-time]

end
@#$#@#$#@
GRAPHICS-WINDOW
261
10
730
500
28
28
8.053
1
10
1
1
1
0
1
1
1
-28
28
-28
28
0
0
1
ticks
30.0

BUTTON
21
39
85
72
Setup
Setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
15
85
230
118
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
18
139
242
172
Max-Num-People-Per-Floor
Max-Num-People-Per-Floor
1
10
1
1
1
NIL
HORIZONTAL

MONITOR
53
252
189
297
Elevator Floor
elevator-floor-position
0
1
11

MONITOR
16
316
234
369
Approximate Avg Waiting Time (sec)
Average-Time
2
1
13

BUTTON
103
38
229
71
Infinite Spawn
infinite-spawn
T
1
T
OBSERVER
NIL
E
NIL
NIL
1

SLIDER
38
193
210
226
Elevator-Capacity
Elevator-Capacity
1
15
5
1
1
NIL
HORIZONTAL

@#$#@#$#@
## Who did this?

Michael Liang Period 9
Brian Yang Period 3

## What is it?

This is an elevator simulation, which simulates the average time a person will have to wait for an elevator to get to the floor they're on and move them to the floor they want to go to. Users should learn how certain factors or combination of factors, such as the number of people waiting for the elevator on each floor and the capacity of the elevator, determine wait time.

## Goals

Floor Background 1 hour COMPLETED  
Elevator Background 1.2 hours COMPLETED
People 1 Hours COMPLETED 
Functioning Elevator 4 hours COMPLETED
Moving People to Elevator 2 hours COMPLETED
Merging 0.5 hours COMPLETED

## How to Use It

First click the setup button and then the go button immediately after. If you want to change the slider of number of people per floor during the simulation and see the effetcs, change the slider and then hit the setup and go buttons again. You can change the slider during the simulation and see if the effects if Infinite Spawn is clicked. The Elevator-Capacity slider can be changed at any point during the simulation while there are people waiting at the elevator doors or while there are people in the elevators. 

## Things to Notice

The user should notice how many people are waiting at the elevator doors as the number of people per floor being spawned increases. The user should pay attention to the average waiting time monitor, especially when Infinite Spawn is clicked. When the elevator is moving, the user should notice how the monitor, Elevator Floor, also changes according to the location of the elevator.   

## Things to Try

First set the slider value for Max-Num-People-Per-Floor to 1. Since there aren't too many people waiting for the elevator, the user can see how the elevator works and the rules that it abides by. As the user increases the amount of people per floor to spawn, the user should also try to change the capacity of the elevator while the simulation is being run. Then the user should click on Infinite Spawn and let more people spawn as the simulation runs. 

## How It Works

Whenever a turtles reaches the elevator door, the elevator button, which is a patch, calls the elevator. The button changes color, and the label of that patch, which is the floor number, is added to elevator-queue. The global variable elevator-queue is a list of floors that the elevator has to go to. Floor numbers will also be added when turtles get into the elevator. When turtles get into the elevator, the turtles are assigned random floor numbers, which designate which floor they "want" to go to. If the floor number that is assigned to a turtle is the same as the floor that the turtle was just in, the turtle is reassigned another label. The elevator-queue is updated and sorted every time the go function is called by the go button. The first element/floor number in the list is the first number that the elevator will go towards. Since the list is being updated every time the go button calls the go function, the floor that the elevator is going towards could change even if the elevator has not reached the floor it WAS trying to go to before. For example, the elevator could be heading towards floor 8 from floor 6, but then someone at floor 7 presses the elevator button that calls the elevator to that floor. The elevator will stop at floor 7 to pick up people waiting at the elevator doors on that floor, and then it will continue to floor 8. 

## Achievements

We used mod to create the background. This greatly reduced the time spent on making the background, because there are a lot of patches, and using the features > and < would take up much more space and time to type. 

We used patch-at-heading-and-distance to make the elevator move up and down. If it weren't for this feature, we would have used turtles for the elevator, which would require much more features to link them together and move. 

We also thought it would more cumbersome to have to deal with the two elevator functions, move-elevator-up and move-elevator-down, so we combined the two into one function, move-elevator. Then we used move-elevator to move the elevator in the go function instead of having to use both move-elevator-up and move-elevator-down. 

One of the most difficult things to program was the elevator. We had to program where the elevator had to go to, and this was difficult because the elevator shouldn't just go up and down to the nearest floor where someone is waiting for the elevator. An elevator in real-life follows a certain set of rules. Eventually, we decided to use a list/queue to tell the elevator where to go to. Each time someone calls the elevator on a floor or presses a button in the elevator, the floor number is added to the queue. The first number in the queue should be the floor that the elevator has to go to.   

To get the turtles to detect when the elevator has fully come up and reached a floor, we used a global variable and a counter. Depending on the value of the counter, elevator-absolute-position, we changed the boolean value of the global variable, reached-a-floor?. The turtles can only get into the elevator if reached-a-floor is true. 

To ensure that the turtles getting on the elevator would not choose to go to the floor they're already on, we used a while loop to reset the turtles' labels until the label was a number other than the number of the floor they were already on. 
 
## Learning, with citations

We used patch-at-heading-and-distance to make the elevator. We found this feature in the manuals, We used this feature because coding the elevator to move up and down would otherwise take a long time. 
We also used with-min and with-max to program the elevator buttons, and the top/bottom of the elevator. The primitive with-min takes two inputs, with one being the agent-set and the other being the quality of the agent. For example, with-min turtles [xcor] would create a subset of turtles with the minimum xcor. We also found this feature in the NetLogo manual.

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for   Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL

Shepherds Model Citation:

Wilensky, U. (1998).  NetLogo Shepherds model.  http://ccl.northwestern.edu/netlogo/models/Shepherds.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Flocking Vee Formations presented by Lucy Posner:

Wilkerson-Jerde, M., Stonedahl, F. and Wilensky, U. (2009).  NetLogo Flocking Vee Formations model.  http://ccl.northwestern.edu/netlogo/models/FlockingVeeFormations.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Isaac, Alan. "Netlogo Programming: An Introduction." Netlogo Programming. American University. Web. 18 Jan. 2015. <https://subversion.american.edu/aisaac/notes/netlogo-intro.xhtml>.

"Turtles Move in Direction of Patch with Pcolor = X." Stackoverflow. Stack Exchange, Inc., 6 Dec. 2013. Web. 19 Jan. 2015. <http://stackoverflow.com/questions/20426139/turtles-move-in-direction-of-patch-with-pcolor-x>.

Piazza - every.nlogo by Mr. Holmes

Imported Shape from Turtle Shape Editor

**Did we understand everything we coded?**

We understood most of what we coded except possibly the reset-timer button. When we were debugging, we created a monitor for the timer. The timer kept on going even though the setup button was already pressed and the go button was not being pressed. Thanks to Mr. Holmes and David Huang for letting me know about every. 

## Bugs, mis-features, and possible improvements

An improvement would be that there could have been two elevators; one elevator for going up and the other for going down. We could have also made breeds of turtles to vary the speeds of the people. This would vary the the time more. 

Another improvement would be that we could make the elevator wait for people to get to the elevator instead of only allowing people already at the elevator door to get on. 

The average time only changes when turtles get off the elevator because while they are still in the elevator, the amount of time they have to wait to get to their destination is still indefinite. We could have thought of a way to change it so that we could predict the average time while a turtle is in the elevator. 

When the turtles get off the elevator and disappear, they actually become hidden so that their start-time and end-time values can still contribute to the average time. We could have improved the program by having them die yet still keep their start-time and end-time values. 

When people spawn, they might blend in with the background.  

The elevator buttons may flash when people are getting off or on the elevator. 

There is some lag when the elevator starts running. 

The elevator sometimes glitches out while it is moving. 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person construction
false
0
Rectangle -7500403 true true 123 76 176 95
Polygon -1 true false 105 90 60 195 90 210 115 162 184 163 210 210 240 195 195 90
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Circle -7500403 true true 110 5 80
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -955883 true false 180 90 195 90 195 165 195 195 150 195 150 120 180 90
Polygon -955883 true false 120 90 105 90 105 165 105 195 150 195 150 120 120 90
Rectangle -16777216 true false 135 114 150 120
Rectangle -16777216 true false 135 144 150 150
Rectangle -16777216 true false 135 174 150 180
Polygon -955883 true false 105 42 111 16 128 2 149 0 178 6 190 18 192 28 220 29 216 34 201 39 167 35
Polygon -6459832 true false 54 253 54 238 219 73 227 78
Polygon -16777216 true false 15 285 15 255 30 225 45 225 75 255 75 270 45 285

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
