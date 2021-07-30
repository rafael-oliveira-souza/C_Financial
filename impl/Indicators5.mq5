//+------------------------------------------------------------------+
//|                                                          CCI.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

CPositionInfo  tradePosition;                   // trade position object
CTrade tradeLib;

enum TYPE_CANDLE{
   WEAK,
   STRONG,
   HAMMER,
   UNDECIDED,
};

enum OPERATOR{
   EQUAL,
   MAJOR,
   MINOR
};

enum ORIENTATION{
   UP,
   DOWN,
   MEDIUM
};

enum TYPE_NEGOCIATION{
   BUY,
   SELL,
   NONE
};

enum POWER{
   ON,
   OFF
};

enum COORDINATE{
   HORIZONTAL,
   VERTICAL
};

struct CandleInfo {
   ORIENTATION orientation;
   TYPE_CANDLE type;
   double close;
   double open;
   double high;
   double low;
};

struct ResultOperation {
   double total;
   double profits;
   double losses;
   double liquidResult;
   double profitFactor;
   bool instantiated;
};

struct MainCandles {
   MqlRates actual;
   MqlRates last;
   MqlRates secondLast;
   bool instantiated;
};


struct BordersOperation {
   double max;
   double min;
   double central;
   bool instantiated;
   ORIENTATION orientation;
};

struct PeriodProtectionTime {
   string dealsLimitProtection;
   string endProtection;
   string startProtection;
   bool instantiated;
};

input POWER  USE_RSI = ON;
input POWER  USE_STHOCASTIC = ON;
input POWER  USE_FORCE_INDEX = ON;
input POWER  EVALUATION_BY_TICK = ON;
input POWER  USE_HEIKEN_ASHI = OFF;
input POWER  USE_INVERSION = OFF;
input POWER  USE_AVERAGES = OFF;
input POWER  POWER_OFF_MOVE_STOP = OFF;
input double PERCENT_INVERSION = 90;
input double MULTIPLIER_VOLUME = 4;
input double PERCENT_MOVE_STOP = 50;
input double ACCEPTABLE_SPREAD = 25;
input int PERIOD = 5;
input int PONTUATION_ESTIMATE = 60;
input double ACTIVE_VOLUME = 0.1;
input double TAKE_PROFIT = 2000;
input double STOP_LOSS = 600;
input string SCHEDULE_START_DEALS = "23:20";
input string SCHEDULE_END_DEALS = "01:00";
input string SCHEDULE_START_PROTECTION = "00:00";
input string SCHEDULE_END_PROTECTION = "00:00";
input ulong MAGIC_NUMBER = 3232131231231231;
input POWER USE_MAGIC_NUMBER = ON;
input int NUMBER_ROBOTS = 100;

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 


double averages[], CCI5[], RVI15[], RVI25[], CCI[], RSI[], RVI1[], RVI2[], STHO1[], STHO2[], valuePrice = 0;
int handleICCI, handleICCI5, handleIRVI5, handleIRSI, handleIRVI, handleStho, handleFI, handleWeek, handleAverages[], countAverage = 0;
ORIENTATION orientMacro = MEDIUM;
BordersOperation bordersFractal;
int periodAval = 3, countRobots = 0, countCandles = 0;
bool waitNewCandle = false;
ulong robots[];
//+------------------------------------------------------------------+
//                                                                          | Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      
      handleIRVI = iRVI(_Symbol,PERIOD_CURRENT,3);
      handleICCI = iCCI(_Symbol,PERIOD_CURRENT,14,PRICE_TYPICAL);
      handleICCI5 = iCCI(_Symbol,PERIOD_M2,14,PRICE_TYPICAL);
      handleWeek = iMA(_Symbol,PERIOD_H1,1,0,MODE_SMA,PRICE_CLOSE);
      
      if(USE_AVERAGES== ON){
         ArrayResize(handleAverages, 10);
         handleAverages[0] = iMA(_Symbol,PERIOD_CURRENT,5,0,MODE_SMA,PRICE_CLOSE);
         handleAverages[1] = iMA(_Symbol,PERIOD_CURRENT,10,0,MODE_SMA,PRICE_CLOSE);
         handleAverages[2] = iMA(_Symbol,PERIOD_CURRENT,20,0,MODE_SMA,PRICE_CLOSE);
         handleAverages[3] = iMA(_Symbol,PERIOD_CURRENT,40,0,MODE_SMA,PRICE_CLOSE);
         handleAverages[4] = iMA(_Symbol,PERIOD_CURRENT,60,0,MODE_SMA,PRICE_CLOSE);
         handleAverages[5] = iMA(_Symbol,PERIOD_CURRENT,80,0,MODE_SMA,PRICE_CLOSE);
         handleAverages[6] = iMA(_Symbol,PERIOD_CURRENT,100,0,MODE_SMA,PRICE_CLOSE);
         handleAverages[7] = iMA(_Symbol,PERIOD_CURRENT,200,0,MODE_SMA,PRICE_CLOSE);
         handleAverages[8] = iMA(_Symbol,PERIOD_CURRENT,300,0,MODE_SMA,PRICE_CLOSE);
         handleAverages[9] = iMA(_Symbol,PERIOD_CURRENT,400,0,MODE_SMA,PRICE_CLOSE);
      }
      
      if(USE_STHOCASTIC == ON){
         handleStho=iStochastic(_Symbol,PERIOD_CURRENT,14,3,3,MODE_SMA,STO_LOWHIGH);
      }
      

      if(USE_RSI == ON){
         handleIRSI = iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE);
      }
      
      if(USE_FORCE_INDEX == ON){
         handleFI = iForce(_Symbol,PERIOD_CURRENT,14,MODE_SMA,VOLUME_TICK);
      }
      
      ArrayResize(robots, NUMBER_ROBOTS + 2);
      for(int i = 0; i < NUMBER_ROBOTS; i++)  {
         robots[i] = MAGIC_NUMBER + i; 
      }
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
void OnTick()
  {
//---
   if(!verifyTimeToProtection()){
      int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
      if(copiedPrice == 3){
         double spread = candles[periodAval-1].spread;
         if(hasNewCandle()){
            if(countCandles > 5){
               waitNewCandle = false;
               countCandles = 0;
            }
            countCandles++;
            Print("New Candle");
            toNegociate(spread);
         }else{
            if(EVALUATION_BY_TICK == ON){
               moveAllPositions(spread);
            }
            if(USE_INVERSION == ON){
               invertAllPositions();
            }
         }
      }   
    }else{
      Print("Horario de proteção");
      int pos = PositionsTotal() - 1;
      for(int i = pos; i >= 0; i--)  {
         if(hasPositionOpen(i)){
            double profit = PositionGetDouble(POSITION_PROFIT);
            if(profit >= 0){
               closeBuyOrSell(i);
            }
         }
      }
   }
}

void toNegociate(double spread){
    if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval && 
      CopyBuffer(handleIRVI,0,0,periodAval,RVI1) == periodAval &&    
      CopyBuffer(handleIRVI,1,0,periodAval,RVI2) == periodAval){
      ORIENTATION orientCCI, orientRVI;
      
      orientCCI = verifyCCI(CCI[periodAval-1]);
      orientRVI = verifyRVI(RVI1[periodAval-1], RVI2[periodAval-1]);
      Print("CCI: " + verifyPeriod(orientCCI));
      Print("RVI: " + verifyPeriod(orientRVI));
      if( spread <= ACCEPTABLE_SPREAD){
         if(orientCCI != MEDIUM && (orientCCI == orientRVI)){
            realizeDealIndicators(orientCCI);
         }
      }
      }else{
      if(USE_INVERSION == ON){
         invertAllPositions();
      }
      
      if(EVALUATION_BY_TICK == OFF){
         moveAllPositions(spread);
      }
   }
}

string verifyPeriod(ORIENTATION orient){
   if(orient == DOWN){
      return "DOWN";
   }
   if(orient == UP){
      return "UP";
   }
   
   return "MEDIUM";
}

void realizeDealIndicators(ORIENTATION orientCCI){
   if(USE_RSI == ON){
      realizeDealsRSI(orientCCI);
   }else{
      if(USE_STHOCASTIC == ON){
         realizeDealsSthocastic(orientCCI);
      }else{
         verifyToBuyOrToSell(orientCCI, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT);
      }
   }
}

void realizeDealsRSI(ORIENTATION orientCCI){    
   if(CopyBuffer(handleIRSI,0,0,periodAval,RSI) == periodAval){
      ORIENTATION orientRSI = verifyRSI(RSI[periodAval-1], RSI[0]);
      Print("RSI: " + verifyPeriod(orientRSI));
      if(orientCCI == orientRSI){
         if(USE_STHOCASTIC == ON ){
            realizeDealsSthocastic(orientCCI);
         }else{
            verifyToBuyOrToSell(orientCCI, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT);
         }
      }
   }
}

void realizeDealsSthocastic(ORIENTATION orientCCI){
   if( CopyBuffer(handleStho,0,0,periodAval,STHO1) == periodAval && CopyBuffer(handleStho,1,0,periodAval,STHO2) == periodAval){
      ORIENTATION orientSTHO = verifySTHO(STHO1[periodAval-1], STHO2[periodAval-1]); 
      Print("STHOCASTIC: " + verifyPeriod(orientSTHO));
      if(orientCCI == orientSTHO ){
         verifyToBuyOrToSell(orientCCI, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT);
      }
   }
}

void verifyToBuyOrToSell(ORIENTATION orient, double volume, double stop, double take){
   if(USE_FORCE_INDEX == ON){
      ORIENTATION orientFI = verifyForceIndex();
      if(orientFI == orient){
         executeOrderByRobots(orient, volume, stop, take);
      }
   }else{
      executeOrderByRobots(orient, volume, stop, take);
   }
}

void executeOrderByRobots(ORIENTATION orient, double volume, double stop, double take){
  if(countRobots < NUMBER_ROBOTS){
      if(USE_AVERAGES== ON){
         int countAv = 0, up = 0, down = 0;
         double avs[];
         for(int i = 0; i < 10; i++)  {
            if(CopyBuffer(handleAverages[i],0,0,periodAval,avs) == periodAval){
               if(candles[0].close > avs[periodAval-1] && candles[0].close > avs[periodAval-2]){ 
                  down++;
               }
               if(candles[0].close < avs[periodAval-1] && candles[0].close < avs[periodAval-2]){
                  up++;
               }
            }
         }
         
          ORIENTATION orientCCI5 = orient;
          if(CopyBuffer(handleICCI5,0,0,periodAval,CCI5) == periodAval){
               orientCCI5 = verifyCCI(CCI5[periodAval-1]);
          }
         
         if(USE_HEIKEN_ASHI == ON){
            ORIENTATION orientHeiken = verifyHeikenAshi(PERIOD);
            if(up >= 7 && orient == UP && orientHeiken != orient && orientCCI5 == orient){
               volume = volume * MULTIPLIER_VOLUME;
            }
            else if(down >= 7 && orient == DOWN && orientHeiken != orient && orientCCI5 == orient){
               volume = volume * MULTIPLIER_VOLUME;
            }
         }else{
            if(up >= 7 && orient == UP && orientCCI5 == orient ){
               volume = volume * MULTIPLIER_VOLUME;
            }
            else if(down >= 7 && orient == DOWN && orientCCI5 == orient){
               volume = volume * MULTIPLIER_VOLUME;
            }
         }
      }
      
      toBuyOrToSell(orient, volume, stop, take, robots[countRobots]);
      countRobots++;
  }else{
      countRobots = PositionsTotal();
  }
}

void invertAllPositions(){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      if(hasPositionOpen(i)){
         useInversion(PONTUATION_ESTIMATE, i);
      }
   }
}

void moveAllPositions(double spread){
   if(POWER_OFF_MOVE_STOP == OFF){
      int max, min, pos = PositionsTotal() - 1;
      double  average[];
      
      if(CopyBuffer(handleWeek,0,0,PERIOD,average) == PERIOD){
         max = ArrayMaximum(average, 0, PERIOD);
         min = ArrayMinimum(average, 0, PERIOD);
         
         datetime actualTime = TimeCurrent();
         drawHorizontalLine(average[max], actualTime, "border-max", clrYellow);
         drawHorizontalLine(average[min], actualTime, "border-min", clrYellow);
      }
      
      for(int i = pos; i >= 0; i--)  {
         if(hasPositionOpen(i)){
            activeStopMovelPerPoints(PONTUATION_ESTIMATE+spread, i);
         }
      }
   }
}

ORIENTATION verifyForceIndex(){
   double forceIArray[], forceValue, fiMax = 0, fiMin = 0;
   //ArraySetAsSeries(forceIArray, true);   
   
   if(CopyBuffer(handleFI,0,0,handleFI,forceIArray) == handleFI){
      forceValue = NormalizeDouble(forceIArray[handleFI-1], _Digits);
      //fiMax = forceIArray[ArrayMaximum(forceIArray,0,handleFI/2)];
      //fiMin = forceIArray[ArrayMinimum(forceIArray,0,handleFI/2)];
      //points = calcPoints(fiMax, 0);
      //points = calcPoints(fiMin, 0);
      if(forceValue >= 0.05 ){
         return DOWN;
      }else if(forceValue <= -0.05 ){
         return UP;
      }
   }
   
   return MEDIUM;
}
  
ORIENTATION verifyHeikenAshi(int period){
   MqlRates newCandle, prevCandle, actualCandle;
   int periodHeiken = period + 3;
   int down = 0, up = 0, doji = 0, lastDown = 0, lastUp = 0, lastDoji = 0;
   double points, shadowH, shadowL;
   
   int copiedPrice = CopyRates(_Symbol,_Period,0,periodHeiken,candles);
   if(copiedPrice == periodHeiken){
      for(int i = 0; i < periodHeiken-2; i++){
         prevCandle = candles[i];
         actualCandle = candles[i+1];
         newCandle.close = (actualCandle.open + actualCandle.high + actualCandle.low + actualCandle.close) / 4;
         newCandle.open = (prevCandle.open + prevCandle.close) / 2;
       
          if(actualCandle.high >= actualCandle.open && actualCandle.high >= actualCandle.close){
            newCandle.high = actualCandle.high;
          }else if(actualCandle.open >= actualCandle.high && actualCandle.open >= actualCandle.close){
            newCandle.high = actualCandle.open;
          }else if(actualCandle.close >= actualCandle.open && actualCandle.close >= actualCandle.high){
            newCandle.high = actualCandle.close;
          }
          
          if(actualCandle.high <= actualCandle.open && actualCandle.high <= actualCandle.close){
            newCandle.low = actualCandle.high;
          }else if(actualCandle.open <= actualCandle.high && actualCandle.open <= actualCandle.close){
            newCandle.low = actualCandle.open;
          }else if(actualCandle.close <= actualCandle.open && actualCandle.close <= actualCandle.high){
            newCandle.low = actualCandle.close;
          }
          
          points = calcPoints(newCandle.close, newCandle.open);
          if(points > 5){
             if(verifyIfOpenBiggerThanClose(newCandle)){
                shadowH = calcPoints(newCandle.high, newCandle.open);
               shadowL = calcPoints(newCandle.low, newCandle.close);
               if(shadowH >= points && shadowL >= points){
                  if(i >= period ){
                     lastDoji++;
                  }else{
                     doji++;
                  }
               }else{
                  if(i >= period ){
                     lastDown++;
                  }else{
                     down++;
                  }
               }/**/
             }else if(!verifyIfOpenBiggerThanClose(newCandle)){
               shadowH = calcPoints(newCandle.high, newCandle.close);
               shadowL = calcPoints(newCandle.low, newCandle.open);
               if(shadowH >= points && shadowL >= points){
                  if(i >= period ){
                     lastDoji++;
                  }else{
                     doji++;
                  }
               }else{
                  if(i >= period ){
                     lastUp++;
                  }else{
                     up++;
                  }
               }/**/
             }
          }
       }
       
       datetime actual = TimeCurrent();   
       if(down > period /2){
         //drawVerticalLine(actual, "heiken-" + IntegerToString(actual), clrBlue);
         //return DOWN;
         if(lastDoji >= 1){
            drawVerticalLine(actual, "heiken-" + IntegerToString(actual), clrBlue);
            return UP;
         }
         if(lastDown == 1){
            drawVerticalLine(actual, "heiken-" + IntegerToString(actual), clrYellow);
            return DOWN;
         } /**/
       }else if(up > period /2){
         //drawVerticalLine(actual, "heiken-" + IntegerToString(actual), clrYellow);
         //return UP;
         if(lastDoji == 1 ){
            drawVerticalLine(actual, "heiken-" + IntegerToString(actual), clrYellow);
            return DOWN;
         }
         if(lastUp >= 1){
            drawVerticalLine(actual, "heiken-" + IntegerToString(actual), clrBlue);
            return UP;
         }/* */
       }
    }
    
    return MEDIUM;
}

//+------------------------------------------------------------------+

ORIENTATION verifyRVI(double rvi1, double rvi2){
   if(rvi1 < rvi2 && rvi2 < 0){
      //Print("Trend DOWN");
      return DOWN;
   }
   if(rvi1 > rvi2 && rvi1 > 0){
      //Print("Trend UP");
      return UP;
   }
   
   if(rvi1 < rvi2 && rvi1 > 0){
      //Print("CORRECTION DOWN");
      return DOWN;
   }
   if(rvi1 > rvi2 && rvi2 < 0){
      //Print("CORRECTION UP");
      return UP;
   }

   return MEDIUM;
}

ORIENTATION verifySTHO(double stho1, double stho2){
   if(stho1 >= 80 && stho2 >= 70){
      return DOWN;
   }
   if(stho1 <= 20 && stho2 <= 30){
      return UP;
   }

   return MEDIUM;
}

ORIENTATION verifyRSI(double rsi, double rsi0){
   if(rsi >= 70 && rsi0 < 70){
      return DOWN;
   }
   if(rsi <= 30 && rsi0 > 30){
      return UP;
   }

   return MEDIUM;
}

ORIENTATION verifyCCI(double valCCI){
   if(valCCI >= 100){
      return DOWN;
   }
   if(valCCI <= -100){
      return UP;
   }

   return MEDIUM;
}

void useInversion(double points, int position){
   double newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      PositionSelectByTicket(PositionGetTicket(position));
      double profit = PositionGetDouble(POSITION_PROFIT);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double pointsInversion =  MathAbs(profit / ACTIVE_VOLUME);
         double stop = (STOP_LOSS < 100 ? STOP_LOSS : 100),  maxLoss = (STOP_LOSS * PERCENT_INVERSION / 100);
         bool inversion = false;
         ORIENTATION orient = MEDIUM;
         
         if(USE_INVERSION == ON && profit < 0){
            if(PERCENT_INVERSION > 0 && pointsInversion >= maxLoss){
               inversion = true;
               if(STOP_LOSS - maxLoss > stop){
                  stop = STOP_LOSS - maxLoss;
               }
                if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                   closeBuyOrSell(position);
                   realizeDeals(SELL, ACTIVE_VOLUME*MULTIPLIER_VOLUME, stop, TAKE_PROFIT, magicNumber);
                   return;
                }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                   closeBuyOrSell(position);
                   realizeDeals(BUY, ACTIVE_VOLUME*MULTIPLIER_VOLUME, stop, TAKE_PROFIT, magicNumber);
                   return;
                }
            }
         }
      }
   }
}

void  activeStopMovelPerPoints(double points, int position = 0){
   double newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      PositionSelectByTicket(PositionGetTicket(position));
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double tpPrice = PositionGetDouble(POSITION_TP);
         double slPrice = PositionGetDouble(POSITION_SL);
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double entryPoints = 0, pointsInversion =  MathAbs(profit / ACTIVE_VOLUME);
         bool modify = false, inversion = false;
         ORIENTATION orient = MEDIUM;
         newSlPrice = slPrice;
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
            //tpPrice = NormalizeDouble((tpPrice + (points * _Point)), _Digits);
            if(slPrice >= entryPrice ){
               entryPoints = calcPoints(slPrice, currentPrice);
               newSlPrice = NormalizeDouble((slPrice + (points * PERCENT_MOVE_STOP / 100 * _Point)), _Digits);
               modify = true;
            }else if(currentPrice > entryPrice+ (points * PERCENT_MOVE_STOP / 100 * _Point)){
               entryPoints = calcPoints(entryPrice, currentPrice);
               newSlPrice = entryPrice;
               modify = true;
            }
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
          //  tpPrice = NormalizeDouble((tpPrice - (points * _Point)), _Digits);
            if(slPrice <= entryPrice ){
               entryPoints = calcPoints(slPrice, currentPrice);
               newSlPrice = NormalizeDouble((slPrice - (points * PERCENT_MOVE_STOP / 100 * _Point)), _Digits);
               modify = true;
            }else if(currentPrice < entryPrice- (points * PERCENT_MOVE_STOP / 100 * _Point)){
               entryPoints = calcPoints(entryPrice, currentPrice);
               newSlPrice = entryPrice;
               modify = true;
            }
         }
            
         if(modify == true && entryPoints != 0 && entryPoints >= points){
            tradeLib.PositionModify(PositionGetTicket(position), newSlPrice, tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido");
            }
         }
      }
   }
}
      

BordersOperation normalizeTakeProfitAndStopLoss(double stopLoss, double takeProfit){
   BordersOperation borders;
   // modificação para o indice dolar DOLAR_INDEX
   if(stopLoss != 0 || takeProfit != 0){
      if(_Digits == 3){
         borders.min = (stopLoss * 1000);
         borders.max = (takeProfit * 1000);  
      }else{
         borders.min = NormalizeDouble((stopLoss * _Point), _Digits);
         borders.max = NormalizeDouble((takeProfit * _Point), _Digits); 
      }
   }
   
   return borders;
}

void toBuy(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
   tradeLib.Buy(volume, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized); 
}

void toSell(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
   tradeLib.Sell(volume, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);   
}

bool realizeDeals(TYPE_NEGOCIATION typeDeals, double volume, double stopLoss, double takeProfit, ulong magicNumber){
   if(typeDeals != NONE){
   
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
    //  if(hasPositionOpen() == false) {
         if(typeDeals == BUY){ 
            toBuy(volume, borders.min, borders.max);
         }
         else if(typeDeals == SELL){
            toSell(volume, borders.min, borders.max);
         }
         
         if(verifyResultTrade()){
            tradeLib.SetExpertMagicNumber(magicNumber);
            Print("MAGIC NUMBER: " + IntegerToString(magicNumber));
            return true;
         }
      // }
    }
    
    return false;
 }

void closeBuyOrSell(int position){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         tradeLib.PositionClose(ticket);
         if(verifyResultTrade()){
            Print("Negociação concluída.");
         }
      }
   }
}

bool verifyMagicNumber(int position = 0, ulong magicNumberRobot = 0){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      
      if(magicNumberRobot == 0){
         magicNumberRobot = MAGIC_NUMBER;
      }
      
      if(USE_MAGIC_NUMBER == OFF){
         return true;
      }else if(magicNumber == magicNumberRobot){
         return true;
      }
   }
   
   return false;
   
}

bool toBuyOrToSell(ORIENTATION orient, double volume, double stopLoss, double takeProfit, ulong magicNumber){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   return realizeDeals(typeDeal, volume, stopLoss, takeProfit, magicNumber);
   //getHistory();
}

bool hasPositionOpen(int position ){
    string symbol = PositionGetSymbol(position);
    if(PositionSelect(symbol) == true) {
      return true;       
    }
    
    return false;
}

bool verifyResultTrade(){
   if(tradeLib.ResultRetcode() == TRADE_RETCODE_PLACED || tradeLib.ResultRetcode() == TRADE_RETCODE_DONE){
      printf("Ordem de %s executada com sucesso.");
      return true;
   }else{
      Print("Erro de execução de ordem ", GetLastError());
      ResetLastError();
      return false;
   }
}

BordersOperation drawBorders(double precoAtual, double pontuationEstimateHigh = 0, double pontuationEstimateLow = 0){
   BordersOperation borders;
   /*
   int numCandles = 2;
   int copiedPrice = CopyRates(_Symbol,_Period,0,numCandles,candles);
   if(copiedPrice == numCandles){
      for(int i = 0; i < numCandles; i++){
         pontuationEstimateHigh += (candles[i].high) ;
         pontuationEstimateLow += (candles[i].low);
      }
      pontuationEstimateHigh = pontuationEstimateHigh /numCandles;
      pontuationEstimateLow = pontuationEstimateLow /numCandles;
      borders.max = MathAbs(_Point * pontuationEstimateHigh + precoAtual);
      borders.min = MathAbs(_Point * pontuationEstimateLow - precoAtual);
   }*/
   
   borders.max = MathAbs(_Point * pontuationEstimateHigh + precoAtual);
   borders.min = MathAbs(_Point * pontuationEstimateLow - precoAtual);
  
   drawHorizontalLine(borders.max, 0, "BorderMax", clrYellow);
   drawHorizontalLine(borders.min, 0, "BorderMin", clrYellow);
   //Print("Atualização de Bordas");
   
   return borders;
}

bool hasNewCandle(){
   static datetime lastTime = 0;
   
   datetime lastBarTime = (datetime)SeriesInfoInteger(Symbol(),PERIOD_CURRENT,SERIES_LASTBAR_DATE);
   
   //primeira chamada da funcao
   if(lastTime == 0){
      lastTime = lastBarTime;
      return false;
   }
   
   if(lastTime != lastBarTime){
      lastTime = lastBarTime;
      return true;
   }
   
   return false;
}

void drawHorizontalLine(double price, datetime time, string nameLine, color indColor){
   ObjectCreate(ChartID(),nameLine,OBJ_HLINE,0,time,price);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
   ObjectMove(ChartID(),nameLine,0,time,price);
}

void drawArrow(datetime time, string nameLine, double price, ORIENTATION orientation, color indColor){
   if(orientation == UP){
      ObjectCreate(ChartID(),nameLine,OBJ_ARROW_UP,0,time,price);
      ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   }else{
      ObjectCreate(ChartID(),nameLine,OBJ_ARROW_DOWN,0,time,price);
      ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   }
}

void drawVerticalLine(datetime time, string nameLine, color indColor){
   ObjectCreate(ChartID(),nameLine,OBJ_VLINE,0,time,0);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
}

void createButton(string nameLine, int xx, int yy, int largura, int altura, int canto, int tamanho, string fonte, string text, long corTexto, long corFundo, long corBorda, bool oculto){
   ObjectCreate(ChartID(),nameLine,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,nameLine,OBJPROP_XDISTANCE,xx);
   ObjectSetInteger(0,nameLine,OBJPROP_YDISTANCE, yy);
   ObjectSetInteger(0,nameLine,OBJPROP_XSIZE, largura);
   ObjectSetInteger(0,nameLine,OBJPROP_YSIZE, altura);
   ObjectSetInteger(0,nameLine,OBJPROP_CORNER, canto);
   ObjectSetInteger(0,nameLine,OBJPROP_FONTSIZE, tamanho);
   ObjectSetString(0,nameLine,OBJPROP_FONT, fonte);
   ObjectSetString(0,nameLine,OBJPROP_TEXT, text);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR, corTexto);
   ObjectSetInteger(0,nameLine,OBJPROP_BGCOLOR, corFundo);
   ObjectSetInteger(0,nameLine,OBJPROP_BORDER_COLOR, corBorda);
}

bool verifyTimeToProtection(){
   datetime now = TimeCurrent();
   bool timeDeals = timeToProtection(SCHEDULE_START_DEALS, SCHEDULE_END_DEALS);
   bool timeProtect = timeToProtection(SCHEDULE_START_PROTECTION, SCHEDULE_END_PROTECTION);
   if(timeDeals || timeProtect){
     // Print("Horario de proteção ativo");
      return true;
   }
   
   return false;
}

bool timeToProtection(string startTime, string endTime){
   datetime now = TimeCurrent();
   datetime start = StringToTime(startTime);
   datetime end = StringToTime(endTime);
   
   if(startTime == "00:00" && endTime == "00:00"){
      return false;
   }else{
      if(now > start && now < end){
         return true;
      }
   }
   
   return false;
}

bool verifyIfOpenBiggerThanClose(MqlRates& candle){
   return candle.open > candle.close;
}

ORIENTATION getOrientationPerCandles(MqlRates& prev, MqlRates& actual){
   if(actual.open > prev.open){
      return UP;
   }else if(actual.open < prev.open){
      return DOWN;
   }
   
   return MEDIUM;
}


MainCandles generateMainCandles(){
   MainCandles mainCandles;
   int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
   if(copiedPrice == 3){
      mainCandles.actual = candles[2];
      mainCandles.last = candles[1];
      mainCandles.secondLast = candles[0];
      mainCandles.instantiated = true;
   }else{
      mainCandles.instantiated = false;
   }
   
   return mainCandles;
}

bool isNewDay(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   
   if((structActual.day_of_year - structDate.day_of_year) > 0){
      return true;
   }else{
      return false;
   }
}

int getActualDay(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   return (structActual.day_of_year - structDate.day_of_year);
}

double calcPoints(double val1, double val2, bool absValue = true){
   if(absValue){
      return MathAbs(val1 - val2) / _Point;
   }else{
      return (val1 - val2) / _Point;
   }
}

void instanciateBorder(BordersOperation& borders){
     borders.max = 0;
     borders.min = 0;
     borders.central = 0;
     borders.instantiated = false;
     borders.orientation = MEDIUM;
}
