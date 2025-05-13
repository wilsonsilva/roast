// Sample JavaScript file for testing interpolation in workflows

class Calculator {
  constructor() {
    this.memory = 0;
  }

  add(number) {
    this.memory += number;
    return this.memory;
  }

  subtract(number) {
    this.memory -= number;
    return this.memory;
  }

  multiply(number) {
    this.memory *= number;
    return this.memory;
  }

  divide(number) {
    if (number === 0) {
      throw new Error("Division by zero!");
    }
    this.memory /= number;
    return this.memory;
  }

  getMemory() {
    return this.memory;
  }

  clear() {
    this.memory = 0;
    return this.memory;
  }
}

// Example usage
if (require.main === module) {
  const calc = new Calculator();
  calc.add(10);
  calc.multiply(2);
  calc.subtract(5);
  console.log(`Result: ${calc.getMemory()}`);
}