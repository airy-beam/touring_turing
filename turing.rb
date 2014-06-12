# "Touring Turing" or Simulation of a Turing Machine
# Etude #13 from Charles Wetherell's "Etudes for Programmers"
# Author: aleksi13
# Date: June 2014

# This program needs two files as input:
# * program file with the rules table for the Turing machine, and
# * data file with the initial contents of the tape (data).
input_program = 'program_sum.turing'
input_tape = 'tape_sum.turing'
# Blank symbol in both input files is to be represented by "~" character
$blank_sym = "~"
# Columns in program file should be delimited by TAB.
$delim_sym = "\t"
# Time control option (in seconds)
# Use 0 to turn this option off
time_control_sec = 0

# First of all, we need to load the program (commands) into the machine
# Each command consists of a given current state of the machine and current symbol on the tape, and 
# it matches them to a specific action, which includes a new (changed) state of the machine, 
# some print operation on the tape, and direction of following movement of the head on the tape
# This can be represented by classes Command and Action, respectively.
class Action
  attr_accessor :final_state, :print_oper, :tape_motion
end

class Command
  attr_accessor :cur_state, :tape_sym, :action
end

begin
# Table of commands can be stored as Hash for ease of access
program = Hash.new
program_file = File.open(input_program, 'r')

while !program_file.eof?
   # Reading the input program line by line
   file_line = program_file.readline.delete!("\n")
   # Ignore comments in input file, marked by '#'
   unless "#" == file_line[0..0] or "" == file_line
     cur_command = Command.new
     cur_command.action = Action.new
     cur_command.cur_state, cur_command.tape_sym, 
       cur_command.action.final_state, cur_command.action.print_oper, 
         cur_command.action.tape_motion = file_line.split($delim_sym)
         
     if ( ( cur_command.tape_sym.size != 1 ) or ( cur_command.action.print_oper.size != 1 ) ) then
       raise 'Incorrect input program: tape symbols should be single characters only!'
     end
     
     if ( ( cur_command.action.tape_motion != 'R' ) and
          ( cur_command.action.tape_motion != 'L' ) and
          ( cur_command.action.tape_motion != 'N' ) ) then
       raise 'Incorrect input program: Tape-motion can only take values "L" for one step left, "R" for one step right, or "N" for staying in the same place!'
     end
         
     program[cur_command.cur_state] ||= Hash.new
     if program[cur_command.cur_state][cur_command.tape_sym] != nil then
       print "Warning: Ambiguous command for state '" + cur_command.cur_state + 
         "' and tape symbol '" + cur_command.tape_sym + "'! The last definition in program will be used.\n"
     end
     program[cur_command.cur_state][cur_command.tape_sym] ||= cur_command.action
   end
end
program_file.close

# Next, load the tape (data) into the machine
# Class Tape inherits from the Array class, its only difference from the native Array is that
# Tape does not allow index to go over the size of the tape, and in case it occurs, it returns 
# the blank symbol. Native array would instead return nil, which is not an appropriate behaviour
# for our Turing machine implementation.
class Tape < Array 
  def [](key)
    if key < self.size then self.fetch(key) else $blank_sym end
  end
end

tape_file = File.open(input_tape, 'r')
while !tape_file.eof?
  file_line = tape_file.readline.delete!("\n")
  unless "#" == file_line[0..0] or "" == file_line
    tape = Tape.new(file_line.split(''))
  end
end
tape_file.close

#Output method for printing tape contents, head position and the machine state
def print_state(tape, head_pos, machine_state)
  # Display machine state
  print "Machine state: " + machine_state + "\n"
  # Print initial state:
  print tape, "\n"
  # Using "^" symbol under the tape to show where the head is now.
  head_pos.times { print " " }; print "^\n"
  print "--next step--\n"
end

# Starting convention is as follows:
# * The machine starts in '1' state, and
# * Head points to the first cell of the tape
machine_state = '1'
head_pos = 0
# Print initial state
print_state(tape, head_pos, machine_state)

# Now go!
cumulative_time = 0
start_time = Time.now.to_f
user_wants_to_stop = false
# Machine will stop either when there is no defined command for current state and tape symbol, or
# when the head goes over left edge of the tape
# (or when user stops it because of long elapsed time)
until ( program[ machine_state ][ tape[ head_pos ] ] == nil ) or 
    ( head_pos < 0 ) or
    ( user_wants_to_stop ) do
  cur_action = program[ machine_state ][ tape[ head_pos ] ]
  tape[ head_pos ] = cur_action.print_oper
  if "L" == cur_action.tape_motion then head_pos -= 1 end
  if "R" == cur_action.tape_motion then head_pos += 1 end
  machine_state = cur_action.final_state
  print_state(tape, head_pos, machine_state)
  
  #Time control option
  if ( 0 != time_control_sec ) then
    if ( Time.now.to_f - start_time ) > time_control_sec then
      cumulative_time += ( Time.now.to_f - start_time )
      print "Program has been running for ", cumulative_time.round, " seconds. Do you want to continue? (y/n): "
      ans = ""
      until ( "y" == ans or "n" == ans ) do ans = gets.delete!("\n") end
      if "n" == ans then user_wants_to_stop = true end
      if "y" == ans then start_time = Time.now.to_f end
    end
  end
end

if user_wants_to_stop then
  print "User has stopped the machine. Contents of the tape is:\n"
else
  print "Machine has stopped. Final contents of the tape is:\n"
end
print tape, "\n"

rescue Exception => e
  puts e.message
end

