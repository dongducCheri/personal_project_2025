# ------------------------------------------------------
# Hexadecimal Keyboard Scanning with Row Polling
# ------------------------------------------------------
# Assign row value to IN_ADDRESS_HEXA_KEYBOARD and
# read OUT_ADDRESS_HEXA_KEYBOARD for the scan code.
# Prints the scan code in hex if a key is pressed.
# Implements dynamic row scanning and simple debouncing.
# ------------------------------------------------------

# Constants for hardware addresses
.eqv IN_ADDRESS_HEXA_KEYBOARD 0xFFFF0012    # Command row selection
.eqv OUT_ADDRESS_HEXA_KEYBOARD 0xFFFF0014   # Read key pressed (row + column)
.eqv SEVENSEG_LEFT 0xFFFF0011               # Dia chi cua den led 7 doan trai
.eqv SEVENSEG_RIGHT 0xFFFF0010              # Dia chi cua den led 7 doan phai

.data
    msg1: .asciz "\nEnter password:\n"
    msg2: .asciz "\nPassword wrong\n"
    msg3: .asciz "\nEnter new password\n"
    msg4: .asciz "\nYou want to change password. Enter your password:\n"
    msg5: .asciz "\nPassword true\n"
    msg6: .asciz "\nPassword must be at least 4 digits\n"
    entered_password: .word 0:100
    default_password: .word 1, 2, 3, 4

.text
main:
    la t4, entered_password     # Address of password
    la t5, default_password     # Address of default password
    li t6, 0                    # Check if need change password
    li s0, 0                    # Loop index
    li s10, 3                   # Max try
    li s9, 0                    # number of incorrect try
    li s8, 16                   # length of default
    li s7, 0                    # length of entered
    li a6, 0                    # Store the nearest row
    li a5, 0                    # Store the nearest scan-code

polling:
    li a3, SEVENSEG_LEFT
    sb a2, 0(a3)
    li a2, 0x0
    li a3, SEVENSEG_RIGHT
    sb a2, 0(a3)
    li t1, 0xffff0012           # Address to send row command
    li t2, 0xffff0014           # Address to read scan code
    li t3, 0x1                  # check 1st row
    sb t3, 0(t1)
    jal check_key
    li t3, 0x2                  # check 2nd row
    sb t3, 0(t1)
    jal check_key
    li t3, 0x4                  # check 3rd row
    sb t3, 0(t1)
    jal check_key
    li t3, 0x8                  # check 4th row
    sb t3, 0(t1)
    jal check_key
    j polling

check_key:          		
    lbu a0, 0(t2)

preprocess_key:  #detect new row   
    bne a6, t3, process_key

continue: #cha
    beqz a0, process_key_2
    beqz a5, process_key
    beq a5, a0, back #unchanged scan-code -> back
    j process_key 

back:
    jr ra

process_key:  #update row cu de polling sau ko xu ly cung 1 hang
    beqz a0, back
    xor a6, a6, a6
    add a6, a6, t3

process_key_2: #cap nhat scan-code moi 
    xor a5, a5, a5
    add a5, a5, a0
    li a2, 0x0
    li a3, SEVENSEG_LEFT
    sb a2, 0(a3)
    li a2, 0x0
    li a3, SEVENSEG_RIGHT
    sb a2, 0(a3)
    li t3, 0x44
    beq a0, t3, new_password
    li t3, 0x88
    beq a0, t3, compare_password
    
    # Check for '0'
    li t3, 0x11                 # Load the scan code for key '0' (0x11)
    beq a0, t3, press_0         # If the pressed key is '0', jump to press_0
    
    # Check for '1'
    li t3, 0x21                 # Load the scan code for key '1' (0x21)
    beq a0, t3, press_1         # If the pressed key is '1', jump to press_1
    
    # Check for '2'
    li t3, 0x41                 # Load the scan code for key '2' (0x41)
    beq a0, t3, press_2         # If the pressed key is '2', jump to press_2
    
    # Check for '3'
    li t3, 0x81                 # Load the scan code for key '3' (0x81)
    beq a0, t3, press_3         # If the pressed key is '3', jump to press_3
    
    # Check for '4'
    li t3, 0x12                 # Load the scan code for key '4' (0x12)
    beq a0, t3, press_4         # If the pressed key is '4', jump to press_4
    
    # Check for '5'
    li t3, 0x22                 # Load the scan code for key '5' (0x22)
    beq a0, t3, press_5         # If the pressed key is '5', jump to press_5
    
    # Check for '6'
    li t3, 0x42                 # Load the scan code for key '6' (0x42)
    beq a0, t3, press_6         # If the pressed key is '6', jump to press_6
    
    # Check for '7'
    li t3, 0x82                 # Load the scan code for key '7' (0x82)
    beq a0, t3, press_7         # If the pressed key is '7', jump to press_7
    
    # Check for '8'
    li t3, 0x14                 # Load the scan code for key '8' (0x14)
    beq a0, t3, press_8         # If the pressed key is '8', jump to press_8
    
    # Check for '9'
    li t3, 0x24                 # Load the scan code for key '9' (0x24)
    beq a0, t3, press_9         # If the pressed key is '9', jump to press_9
    
    jr ra

press_0:
    li t3, 0                    # Store digit '0'
    j store_digit

press_1:
    li t3, 1                    # Store digit '1'
    j store_digit

press_2:
    li t3, 2                    # Store digit '2'
    j store_digit

press_3:
    li t3, 3                    # Store digit '3'
    j store_digit

press_4:
    li t3, 4                    # Store digit '4'
    j store_digit

press_5:
    li t3, 5                    # Store digit '5'
    j store_digit

press_6:
    li t3, 6                    # Store digit '6'
    j store_digit

press_7:
    li t3, 7                    # Store digit '7'
    j store_digit

press_8:
    li t3, 8                    # Store digit '8'
    j store_digit

press_9:
    li t3, 9                    # Store digit '9'
    j store_digit

# Function to store digit into password array
store_digit:
    addi a0, t3, 0
    addi s7, s7, 4
    sw a0, 0(t4)
    li a7, 1
    ecall
   # addi s0, s0, 4
    addi t4, t4, 4
    j polling

new_password:
    addi t6, t6, 1
    li a7, 4
    la a0, msg4  #"\nYou want to change password. Enter your password:\n"
    ecall
    j polling

compare_password:
    la t4, entered_password     # Address of password
    la t5, default_password     # Address of default password
    bgtz a1, change_password
    bne s7, s8, false_password
    li s0, 0

here:
    lw s4, 0(t4)
    lw s5, 0(t5)
    bne s4, s5, false_password
    addi s0, s0, 4
    beq s0, s7, true_password
    addi t4, t4, 4
    addi t5, t5, 4
    j here

true_password:
    li a2, 0x3F
    li a3, SEVENSEG_LEFT
    sb a2, 0(a3)
    li a2, 0x37
    li a3, SEVENSEG_RIGHT
    sb a2, 0(a3)
    la t4, entered_password     # Address of password
    la t5, default_password     # Address of default password
    la a0, msg5
    li s7, 0
    li a7, 4
    li s9, 0
    ecall
    bgtz t6, if_true_for_change
    j polling

if_true_for_change:
    addi a1, a1, 1
    j polling

change_password:
    li   t0, 16           # t0 = 16 bytes
    blt  s7, t0, too_short
    # nếu >=16, thì đi tiếp vào copy mật khẩu
    j    do_copy

too_short:
    la   a0, msg6
    li   a7, 4
    ecall               # in lỗi "Password must be at least 4 digits"
    # reset con trỏ và độ dài, quay lại nhập mật khẩu mới
    li   s7, 0
    la   t4, entered_password
    j    new_password
    
do_copy:
    la   t4, entered_password
    la   t5, default_password
    li   s8, 0
    li   s0, 0

here3:
    lw s4, 0(t4)
    sw s4, 0(t5)
    addi s0, s0, 4
    addi s8, s8, 4
    beq s0, s7, return
    addi t4, t4, 4
    addi t5, t5, 4
    j here3

false_password:
    li a2, 0x3F
    li a3, SEVENSEG_LEFT
    sb a2, 0(a3)
    li a2, 0x88
    li a3, SEVENSEG_RIGHT
    sb a2, 0(a3)
    la t4, entered_password     # Address of password
    la a0, msg2
    li a7, 4
    li s7, 0
    ecall
    addi s9, s9, 1
    bge s9, s10, frozen
    j polling

frozen:
    li s9, 0
    li a0, 60000
    li a7, 32
    ecall
    j polling

return:
    li t6, 0
    li a1, 0
    la a0, msg1
    li a7, 4
    li s7, 0
    ecall
    la t4, entered_password     # Address of password
    la t5, default_password     # Address of default password
    j polling
