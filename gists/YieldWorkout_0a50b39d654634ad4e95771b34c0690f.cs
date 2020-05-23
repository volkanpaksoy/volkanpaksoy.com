using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApplication1
{
    public class YieldWorkout
    {
        public void Run()
        {
            int n = GetUserInput();
            Console.WriteLine();
            Console.WriteLine(string.Format("First {0} Fibonacci numbers:", n));
            
            foreach (int value in FibonacciWithYield(n))
            {
                Console.WriteLine(string.Format("{0}", value));
            }
            
            Console.ReadKey();
        }

        private IEnumerable<int> FibonacciWithYield(int max)
        {
            int f0 = 0;
            int f1 = 1;
            int fn = -1;

            yield return f0;
            yield return f1;

            int i = 0;
            do
            {
                fn = f0 + f1;
                yield return fn;

                f0 = f1;
                f1 = fn;
                i++;
            } while ( i < (max - 2)); // First 2 elements are 0 and 1
        }

        private int GetUserInput()
        {
            Console.WriteLine("*************************************************");
            Console.WriteLine("               Fibonacci calculator              ");
            Console.WriteLine("*************************************************");
            Console.WriteLine("Please enter the number of numbers to calculate: ");

            bool enteredValue = false;
            bool parsed = false;
            int maxNumber = -1;
            do
            {
                parsed = int.TryParse(Console.ReadLine(), out maxNumber);
                if (!parsed || maxNumber <= 2)
                {
                    Console.WriteLine("Invalid number. Please enter a positive integer greater than 2");
                }
                else
                {
                    enteredValue = true;
                }
            } while (!enteredValue);
            
            return maxNumber;
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            new YieldWorkout().Run();
        }
    }    
}
