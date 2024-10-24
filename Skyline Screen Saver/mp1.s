# - Your solution goes here
#
        .section .data                    # Data section (optional for global data)
        .extern skyline_beacon            # Declare the external global variable
	.extern skyline_stars
	.extern skyline_star_cnt
	.extern skyline_win_list

	.equ SKYLINE_STARS_MAX, 1000	
	.equ SKYLINE_WIDTH, 640
	.equ SKYLINE_HEIGHT, 480

	.section .text #declaring the add_star function
	.global add_star
	.type add_star, @function
	.global remove_star
	.type remove_star, @function
	.global add_window
	.type add_window, @function
	.global remove_window
	.type remove_window, @function
	.global draw_star
	.type draw_star, @function
	.global draw_window
	.type draw_window, @function
	.global draw_beacon
	.type draw_beacon, @function

        .global skyline_star_cnd
        .type   skyline_star_cnd, @object

        .text
        .global start_beacon
        .type   start_beacon, @function

start_beacon:

        la t0, skyline_beacon             # Load address of skyline_beacon into t0 (t0 is 64-bit)

        # Store the function arguments into the struct fields
        sd a0, 0(t0)                      # Store img (a0, 64-bit) at offset 0 (8 bytes)

        sh a1, 8(t0)                      # Store x (a1, 16-bit) at offset 8 (after img pointer)

        sh a2, 10(t0)                     # Store y (a2, 16-bit) at offset 10

        sb a3, 12(t0)                     # Store dia (a3, 8-bit) at offset 12

        sh a4, 14(t0)                     # Store period (a4, 16-bit) at offset 14

        sh a5, 16(t0)                     # Store ontime (a5, 16-bit) at offset 16

        ret                               # Return to caller
	

        
add_star:

	
	la t4, SKYLINE_WIDTH
	la t5, SKYLINE_HEIGHT
	bgeu a0, t4, exitNow
	bgeu a1, t5, exitNow
	
	la t0, skyline_stars #loads the address of stars array
	

	la t4, skyline_star_cnt #load addreezs of star count
				#this value is stored at t4 because I use li initially wihch DOES NOT WORK

	lw t1, 0(t4) #loads the current number of stars into t1 MUST USE ADDRESS AS NOT A CONSTANT VARIABLE
	
	li t2, SKYLINE_STARS_MAX #loads max number of stars into t2

	beq t1, t2, exit #checking if max star count has been reached and exiting if it has
	
	#a0 = argument for x coordinate unsigned 16 bits
	#a1 = argument for y coordinate usigned 16 bits
	#a2 = argument for color unsigned 16 bits

	slli t3, t1, 3 #shifting the current number of stars over by 3 which in effect multiplies it by 8
		       #this allows us access the correct element of the star struct since each struct is 
			#8 bytes long this allows us to compute the new stars address inside of the skyline stars
			#array. 

	add t0, t0, t3 #this locates the new stars location inside of the skyline_stars array

	#now that we have accessed the correct location of the new star we store the arugments for the new
	#stars x, y, and color at the appropriate location

	sh a0, 0(t0) #this stores the x coordinate

	sh a1, 2(t0) #stores y coordinate shifted as to not affect the x coords

	sh a2, 6(t0) #stores the color bits after the coordinates

	addi t1, t1, 1 #increments the star count by 1

	sw t1, 0(t4) # stores the star count at the memory address for skyline_star_cnt



	exit:
	ret		
		

remove_star:


	#a0 is x coordinate
	#a1 is y coordinate
	#we must use the x and y coordinate to figure out which star is being removed
	#i will dothis by itterating throught the entire skyline_star array and comparing the x y coords
	#WHILE LOOP TIME BABY

	la t4, SKYLINE_WIDTH
	la t5, SKYLINE_HEIGHT
	bgeu a0, t4, exitNow
	bgeu a1, t5, exitNow
	
	
	la t4, skyline_star_cnt #grabs address that holds current number of stars
	lw t5, 0(t4) #stores number of stars in t5
	addi t1, zero, 0 #creates a new variable that will be used as a counter	
	
	topLoop:#this is the top of our while loops
	beq t1, t5, exitNow
	la t0, skyline_stars #get address of stars arra
	slli t2, t1, 3 #used to calculate where the beggining of the star is in memory
	add t0, t0, t2 #physically moving to the first address of the star
	lh t3, 0(t0) #grabs the x coordinate from the correct mem location in t0
	bne t3, a0, nexts #moves to next star if x coords dont work
	
	lh t3, 2(t0) #grabs y coords
	bne t3, a1, nexts
	j delete #if gets here then the star was found

	nexts:
	addi t1, t1, 1 #iterates back to top of loop
	j topLoop


	delete: #to delete we will overwrite the data of teh current star with the data of the last star
		#this maintains contigous and order dont matter so this works 
		#i was about to no joke iterate through the whole array and shift stuff like a moron
		#big shoutout to natanya for being like "are you stupid"



	addi t5, t5, -1 #subtracts one from total stars also grabs the index
	beq t1, t5, deleteLast
	slli t6, t5, 3 #finds the offset to reach the star desired
	la t0, skyline_stars #resets skyline stars address
	add t0, t0, t6 #goes to last location
	lh t4, 0(t0) #grabs x coord of last star
	sw zero, 0(t0)
	lh t3, 2(t0) #grabs y coord of last star
	sw zero, 2(t0)
	lh t6, 6(t0) #grabs color of last star
	sw zero, 6(t0)

	la t0, skyline_stars #resets skyline stars address
	slli t2, t1, 3
	add t0, t0, t2 #moves back to star being deleted
	sh t4, 0(t0) #stores x coord of last star at deleted stars x coords
	sh t3, 2(t0) #stores y coord of last star at deleted stars y coords
	sh t6, 6(t0) #stores color of last star at deleted stars color

	la t4, skyline_star_cnt
	sw t5, 0(t4) #stores new star count at star count address 
	j exitNow

	deleteLast:
	la t0, skyline_stars
	slli t2, t5, 3
	add t0, t0, t2
	sw zero, 0(t0)
	sw zero, 2(t0)
	sw zero, 6(t0)
	sw t5, 0(t4) #stores pointer one less

	exitNow:
	ret
			

draw_star:

	#a0 is the frame buffer pointer
	#a1 is a pointer to a star construct
	addi sp, sp, -32 #allocating space for registers
	sd ra, 24(sp)	#save return address
	sd s0, 16(sp)
	sd s1, 8(sp)
	sd s2, 0(sp)

	lh s0, 0(a1) #grab x coords
	lh s1, 2(a1) #grab y coords
	lh s2, 6(a1) #grabs the color
	
	li t0, SKYLINE_WIDTH
	mul t0, s1, t0 #multiplying y by the width to get the correct offset
	add t0, t0, s0 #adding x coords for offset
	slli t0, t0, 1 #multiplying by two because each pixel  is 2 bytes
	add t1, a0, t0 #gets address in framee buffer

	sh s2, 0(t1)
	
	ld s2, 0(sp) #restore all save registers
	ld s1, 8(sp)
	ld s0, 16(sp)
	ld ra, 24(sp)
	addi sp, sp, 32

	ret
			

remove_window:


	la t4, SKYLINE_WIDTH
	la t5, SKYLINE_HEIGHT
	bgeu a0, t4, exitNow
	bgeu a1, t5, exitNow
	#a0 is x coord
	#a1 is y coord
	addi sp, sp, -8
	sd ra, 0(sp)

	la t0, skyline_win_list #load the pointer to window list
	ld t1, 0(t0)
	beqz t1, exit2
	ld t2, 0(t1)#grabs pointer to next window

	checkfirst:
	beqz t1, exit2 #if list is empty ends the function
	lh t3, 8(t1) # grabs x coords of current window it moves over 8 bytes because the pointer to the next struct has 8 bytes
	beq t3, a0, checkYFirst #checks if x coords match if they do it jumps to checkY


	checkYFirst:
	lh t3, 10(t1) #grabs y coords of current window
	beq t3, a1, deletionFirst
	j checkMiddle

	checkMiddle:
	beqz t2, exit #if this node is empty means we got to end of list and found nothing so exits
	lh t3, 8(t2) #t1 is now previous node and t2 is now our current this grabs x coords
	beq a0, t3, checkMiddleY
	mv t1, t2 #changes pointers up
	ld t2, 0(t1)
	j checkMiddle

	checkMiddleY:#checks the middle window y and deletes if y matches
	lh t3, 10(t2)
	beq a1, t3, deletion
	mv t1, t2
	ld t2, 0(t1)
	j checkMiddle


	deletion:
	ld t3, 0(t2) #checks the next noed to see if current node is final node
	beqz t3, deletionFinal 
	sd t3, 0(t1) #updates to skip this node
	mv a0, t2	#frees this node up
	call free
	j exit2

	deletionFinal:
	sd zero, 0(t1) #this sets the previous to null
	mv a0, t2
	call free
	j exit2

	deletionFirst:
	ld t2, 0(t1)
	sd t2, 0(t0) #this updates the head to skip the first node
	mv a0, t1
	call free
	j exit2

	exit2:
	ld ra, 0(sp)
	addi sp, sp, 8
	ret

add_window:

	#t0  is x coord
	#a1 is y coord
	#a2 is width
	#a3 is height
	#a4 is color
	
	la t4, SKYLINE_WIDTH
	la t5, SKYLINE_HEIGHT
	bgeu a0, t4, exitNow
	bgeu a1, t5, exitNow

	
	addi sp, sp, -48
	sd ra, 0(sp)
	sd a0, 8(sp) #saving x coord
	sd a1, 16(sp) #savin y coord
	sd a2, 24(sp)
	sd a3, 32(sp)
	sd a4, 40(sp)	


	#unfortunatly this is not the same as add stars and requires the use of malloc as 
	#skyline_win_list is a pointer so we need to allocate space for a new window

	#add t3, zero, a0	
	#add t0, zero, a1

	addi a0, x0, 16 # we allocate 16 bytes of memory for window struct
		  # 8 bytes is pointer 2 for x 2 for y 1 for w and h and 2 for color which is 16
		  

	call malloc #places pointer at a0

	ld a1, 8(sp)
	ld a2, 16(sp)
	ld a3, 24(sp)
	ld a4, 32(sp)
	ld a5, 40(sp)

	beqz a0, exit1
	
	la t1, skyline_win_list #loads address of pointer to skyline window list grabs yhr hrad of the list
	ld t2, 0(t1)
	
	sd t2, 0(a0) #we are now pointing to the new window at where the current head is

	sh a1, 8(a0) #storing x at an offset of 4 bits for the pointer

	sh a2, 10(a0) # storing y coords

	#ld t0, 16(sp)	

	sh a3, 12(a0) #storing w and h
	sb a4, 13(a0)

	#ld t0, 8(sp)
	sh a5, 14(a0) #storing color

	sd a0, 0(t1) #saving the new window pointer adn data at the head of teh list

	exit1:
	ld ra, 0(sp)
	addi sp, sp, 48
	ret
	
	
draw_beacon: #this is literally my draw window code modified slightly to use the beacon img color
	addi sp, sp, -56
        sd ra, 48(sp)
        sd s0, 40(sp)
        sd s1, 32(sp)
        sd s2, 24(sp)
        sd s3, 16(sp)
        sd s4, 8(sp)
        sd s5, 0(sp)

        lh s0, 8(a2) #grabs x coords
        lh s1, 10(a2) #grabs y coords
        lb s2, 12(a2) #grabs dia
        lh s3, 14(a2) #grabs period
        lh s4, 16(a2) #grabs ontime

        #two checks number 1 is if period and #2 is whi;e ontime
        rem s5, a1, s3 #modulus of time against period
        bge s5, s4,  beaconEnd # if the remainder is 0 then period has been hit

	li t0, SKYLINE_WIDTH #loads hte width and height of the image
	li t1, SKYLINE_HEIGHT                      


	li t3, 0 #ycoounter

	beaconY:
	bgeu t3, s2, beaconEnd #if gone beyond the height of the beacon exit
	
	add t4, s1, t3 # y+younter
	bgeu t4, t1, beaconYnext #if y is greater tahn max heigh goes to next y

	li t5, 0

	beaconX:
	bgeu t5, s2, beaconYnext # if x has gone beyond past the width go to next y

	add t2, s0, t5 #x + xcounter
	bgeu t2, t0, skipPixelB #if past max width the skip the pixel

	mul t6, t4, t0 	#this all gets the pixel location in the frame buffer
	add t6, t6, t2
	slli t6, t6, 1
	add t6, a0, t6
	
	
#	slli s4, t3, 2
	
	
#	add s4, s4, t5
	
#	slli s4, s4, 1
	mul s4, t3, s2 
	add s4, s4, t5
	slli s4, s4, 1
	ld s5, 0(a2)
	add s5, s5, s4
	lh s3, 0(s5)
	
	sh s3, 0(t6) #stores the color a the framebuffer location

	skipPixelB:
	addi t5, t5, 1 #increment x counter
	j beaconX

	beaconYnext:
	addi t3, t3, 1 #increment y counter
	j beaconY 

        beaconEnd:
        ld ra, 48(sp)
        ld s0, 40(sp)
        ld s1, 32(sp)
        ld s2, 24(sp)
        ld s3, 16(sp)
        ld s4, 8(sp)
        ld s5, 0(sp)
        addi sp, sp, 56

	ret


	
	
draw_window:
	addi sp, sp, -48            
    	sd ra, 40(sp)               
    	sd s0, 32(sp)               
    	sd s1, 24(sp)               
    	sd s2, 16(sp)               
    	sd s3, 8(sp)                
	sd s4, 0(sp)

    	lhu s0, 8(a1)                
    	lhu s1, 10(a1)               
    	lbu s2, 12(a1)               
    	lbu s3, 13(a1)               
    	lhu s4, 14(a1)               

	li t0, SKYLINE_WIDTH #loads hte width and height of the image
	li t1, SKYLINE_HEIGHT                      

	li t3, 0 #ycoounter

	windowY:
	bgeu t3, s3, drawEnd #if gone beyond the height of the window exit

	add t4, s1, t3 # y+younter
	bgeu t4, t1, windowYnext #if y is greater tahn max heigh goes to next y

	li t5, 0 # xcounter
	 
	windowX:
	bgeu t5, s2, windowYnext # if x has gone beyond past the width go to next y
	
	add t2, s0, t5 #x + xcounter
	bgeu t2, t0, skipPixel #if past max width the skip the pixel

	mul t6, t4, t0 	#this all gets the pixel location in the frame buffer
	add t6, t6, t2
	slli t6, t6, 1
	add t6, a0, t6

	sh s4, 0(t6) #stores the color a the framebuffer location

	skipPixel:
	addi t5, t5, 1 #increment x counter
	j windowX

	windowYnext:
	addi t3, t3, 1 #increment y counter
	j windowY 

	drawEnd:
    	ld ra, 40(sp)              
    	ld s0, 32(sp)              
    	ld s1, 24(sp)              
   	ld s2, 16(sp)              
  	ld s3, 8(sp)
	ld s4, 0(sp)               
  	addi sp, sp, 48	
	ret
	.end
