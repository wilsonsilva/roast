# frozen_string_literal: true

# Sample Ruby file for testing interpolation in workflows

class Calculator
  def initialize
    @memory = 0
  end

  def add(number)
    @memory += number
  end

  def subtract(number)
    @memory -= number
  end

  def multiply(number)
    @memory *= number
  end

  def divide(number)
    raise "Division by zero!" if number.zero?

    @memory /= number
  end

  attr_reader :memory

  def clear
    @memory = 0
  end
end

# Example usage
if __FILE__ == $PROGRAM_NAME
  calc = Calculator.new
  calc.add(10)
  calc.multiply(2)
  calc.subtract(5)
  puts "Result: #{calc.memory}"
end
