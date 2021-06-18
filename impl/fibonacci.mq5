//+------------------------------------------------------------------+
//|                                                   Fibonnacci.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctionBackup.mqh"

input double INIT_POINT = 0;
input double END_POINT = 0;

double initPoint = INIT_POINT;
double endPoint = END_POINT;

int countCrossBorder = 0;
int maxFibonacciValue = 9;
double percentMaxFibonacci = 10;
bool supportAndResistenceAreasDrawed = false;
double fiboPoints[10] = {0, 23.6, 38.2, 50, 61.8, 100, 161.8, 261.8, 432.6, 685.4};
double FiboValues[10];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {  
   ORIENTATION orient = MEDIUM;
   orient = startFibonacci();
}
//+------------------------------------------------------------------+

ORIENTATION startFibonacci(){
   ORIENTATION orientationMacro = MEDIUM;
   calculateBordersFibonacci(initPoint, endPoint);
   
   if(!supportAndResistenceAreasDrawed){
      startSupportAndResistenceAreas();
   }else{
     double borderHigh, borderLow;
     if(FiboValues[maxFibonacciValue] < FiboValues[0]) {
         borderLow = FiboValues[maxFibonacciValue];
         borderHigh = FiboValues[0];
         orientationMacro = UP;
     }  else{
         borderHigh = FiboValues[maxFibonacciValue];
         borderLow = FiboValues[0];
         orientationMacro = DOWN;
     }
   
     if(crossBorderHigh(candles[0].close, borderHigh) ||
        crossBorderLow(candles[0].close, borderLow)){
        double aux = initPoint;
        initPoint = endPoint;
        endPoint = aux;
     }else{
        BordersOperation bordersFibo toLocalizeChannel(candles[0].close);
         //cruzou uma borda superior
        if(crossBorderHigh(candles[0].close, bordersFibo.max)){
           newOrientation = UP;
        }
        //cruzou uma borda inferior
        else if(crossBorderLow(candles[0].close, bordersFibo.min)){
          orientationMacro = DOWN;
        }
     }
   }
        
   return MEDIUM;
}

BordersOperation toLocalizeChannel(double actualValue){
   for(int i = 0; i < max; i++){
      if(FiboValues[i])
   }
}

bool crossBorderHigh(double actualValue, double actualValueFibo){
   //double valueBorder = actualValueFibo + (actualValueFibo * (percentMaxFibonacci/100));
   double valueBorder = actualValueFibo;
   if(actualValue > valueBorder){
      return true;
   }
   
   return false;
}

bool crossBorderLow(double actualValue, double actualValueFibo){
  // double valueBorder = actualValueFibo - (actualValueFibo * (percentMaxFibonacci/100));
   double valueBorder = actualValueFibo;
   if(actualValue < valueBorder){
      return true;
   }
   
   return false;
}


void startSupportAndResistenceAreas(){
   int copiedPrice = CopyRates(_Symbol,_Period,0,1,candles);
   if(copiedPrice == 1){
      MqlRates candle = candles[0];
      if(initPoint == 0 || endPoint == 0){
         datetime actualTime = TimeCurrent();
         if(initPoint == 0){
            initPoint = candle.close;
            drawHorizontalLine(initPoint, actualTime, "endPoint", clrRed);
         }
         if(endPoint == 0){
           double pontuation = MathAbs(candle.close - initPoint) / _Point;
           if(pontuation > 0 && pontuation > PONTUATION_ESTIMATE){
             endPoint = candle.close;
             drawHorizontalLine(endPoint, actualTime, "initPoint", clrRed);
           }
         }
      }
   
      if(initPoint != 0 && endPoint != 0){
        //double aux = initPoint;
        //initPoint = endPoint;
        //endPoint = aux;
        supportAndResistenceAreasDrawed = true;
      }else{
         supportAndResistenceAreasDrawed = false;
      }
   }
}


void calculateBordersFibonacci(double initPoint, double endPoint){
   if(initPoint != 0 && endPoint != 0){
      double points = (endPoint - initPoint) / _Point;
      string nameLineFibo = "fibo", nameOvercrossFibo = "over";
      int max = maxFibonacciValue;
      // endPoint > initPoint -- Cresce pra cima
      if(points > 0){
        for(int i = max, j = 0; i >= 0; i--, j=max-i){
            if(j < 6){
               if(j == 0){
                  nameLineFibo = nameLineFibo + "-initPoint";
                  FiboValues[i]  = NormalizeDouble(initPoint,_Digits);
               }else if(j == 5){
                  nameLineFibo = nameLineFibo + "-endPoint";
                  FiboValues[i]  = NormalizeDouble(endPoint,_Digits);
               }else{ 
                  FiboValues[i]  = NormalizeDouble((initPoint + (points * _Point * fiboPoints[j]) / 100), _Digits);
               }
               drawHorizontalLine(FiboValues[i], TimeCurrent(), nameLineFibo + IntegerToString(i), clrWhite);
            }else{
               FiboValues[i]  = NormalizeDouble((endPoint + ((points * _Point * fiboPoints[j]) / 100)),_Digits);
               drawHorizontalLine(FiboValues[i], TimeCurrent(), nameOvercrossFibo + IntegerToString(i), clrWhite); 
            }
        } 
     }else{ // initPoint > endPoint  -- Cresce pra baixo
        for(int i = 0; i <= max; i++){
            if(i < 6){
               if(i == 0){
                  nameLineFibo = nameLineFibo + "-initPoint";
                  FiboValues[i]  = NormalizeDouble(initPoint,_Digits);
               }else if(i == 5){
                  nameLineFibo = nameLineFibo + "-endPoint";
                  FiboValues[i]  = NormalizeDouble(endPoint,_Digits);
               }else{ 
                  FiboValues[i]  = NormalizeDouble((initPoint + (points * _Point * fiboPoints[i]) / 100),_Digits);
               }
               drawHorizontalLine(FiboValues[i], TimeCurrent(), nameLineFibo + IntegerToString(i), clrWhite);
            }else{
               FiboValues[i]  = NormalizeDouble((endPoint + ((points * _Point * fiboPoints[i]) / 100)),_Digits);
               drawHorizontalLine(FiboValues[i], TimeCurrent(), nameOvercrossFibo + IntegerToString(i), clrWhite); 
            }
        }
     }
      
     Print("Fibonacci finalizado.");
   }
}