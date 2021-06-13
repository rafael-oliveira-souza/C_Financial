//+------------------------------------------------------------------+
//|                                                 TorettoRobot.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "MainFunctions.mqh"

input int BARS_NUM = 3;

input double ACTIVE_VOLUME = 1.0;
input double TAKE_PROFIT = 110;
input double STOP_LOSS = 40;

//input POWER HIGH_OSCILATION = OFF;

input string DEALS_LIMIT_TIME = "17:30";
input string START_PROTECTION_TIME = "12:00";
input string END_PROTECTION_TIME = "13:00";

input int HEIGHT_BUTTON_PANIC = 350;
input int WIDTH_BUTTON_PANIC = 500;

input color HAMMER_COLOR = clrViolet;
input color PERIOD_COLOR = clrGreenYellow;
//input color PERIOD_COLOR_UP = clrBlue;
//input color PERIOD_COLOR_DOWN = clrYellow;

MqlRates candles[];
PeriodProtectionTime period;

MqlRates lastDeal;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   createButton("BotaoPanic", WIDTH_BUTTON_PANIC, HEIGHT_BUTTON_PANIC, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
   period.dealsLimitProtection = DEALS_LIMIT_TIME;
   period.startProtection = START_PROTECTION_TIME;
   period.endProtection = END_PROTECTION_TIME;
  
   startRobots();
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   finishRobots();
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(BARS_NUM < 3){
      Alert("O numero de barras analisadas deve ser maior que 3");
   }else{
      //if(verifyTimeToProtection(period)){
         startDeals();
      //}
   }
   
  }
//+------------------------------------------------------------------+

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
   // Fechar negociacões
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "BotaoPanic"){
         removeDeals();
         Alert("Negociações finalizadas");
      }
   }
}

void startDeals(){
   if(hasNewCandle()){
      if(hasPositionOpen() == true){
        // activeStopMovel(STOP_LOSS);
         /*
         if(decisionCandle == true){
            int copiedPrice = CopyRates(_Symbol,_Period,0,2,candles);
            if(copiedPrice == 2){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  if(candles[0].close > lastDeal.close){
                     activeStopMovel(0, );
                  }
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                   newSlPrice = NormalizeDouble((tick.last + diffSl), _Digits);
                   diffPriceTick = (slPrice - tick.last);
               }
              decisionCandle = false;
              
            }
         }else{
            decisionCandle = true;
         } */
      }else{
         ORIENTATION orient = avaliatePerPeriod();
         if(orient == DOWN || orient == UP){
            bool hasResult = toBuyOrToSell(orient,ACTIVE_VOLUME,STOP_LOSS,TAKE_PROFIT);
            
            if(hasResult == true){
               int copied = CopyRates(_Symbol,_Period,0,1, candles);
               if(copied == 1){
                  lastDeal = candles[0];
               }
            }
         }
      }
      
      getHistory(0);
   }
}

ORIENTATION avaliatePerPeriod(){
   int copied = CopyRates(_Symbol,_Period,0, BARS_NUM+2, candles);
   if(copied >= BARS_NUM){
      int up = 1, down = 1;
      for(int i = 0; i < BARS_NUM-1; i++){
         bool isHammer = MEDIUM;
         //definir se high e low é open ou close
         if(verifyIfOpenBiggerThanClose(candles[i])){
            //descida
            if(candles[i].open >= candles[i+1].open && candles[i].close >= candles[i+1].close){
               down++;
            }
            //subida
            else if(candles[i].open <= candles[i+1].open && candles[i].close <= candles[i+1].close){
               up++;
            }
            /*else {
               isHammer = verifyIfHammer(candles[i]);
               if(isHammer == UP){
                  up++;
               }else if(isHammer == DOWN){
                  down++;
               }
            }*/
         }else{
            //descida
            if(candles[i].close >= candles[i+1].close && candles[i].open >= candles[i+1].open){
               down++;
            }
            //subida
            else if(candles[i].close <= candles[i+1].close && candles[i].open <= candles[i+1].open){
               up++;
            }
             /*else {
               isHammer = verifyIfHammer(candles[i]);
               if(isHammer == UP){
                  up++;
               }else if(isHammer == DOWN){
                  down++;
               } 
            }*/
         }
      }
      
      int nBars = BARS_NUM;      
      string nameStartLine = "period-start";
      string nameEndLine = "period-end";
      string nameBordLine = "period-border";
      MqlRates lastCandle = candles[BARS_NUM-1];
      MqlRates firstCandle = candles[0];
      ObjectDelete(0,nameStartLine);
      ObjectDelete(0,nameBordLine);
      ObjectDelete(0,nameEndLine);
      
      drawVerticalLine(firstCandle.time, nameStartLine, PERIOD_COLOR);
      drawVerticalLine(lastCandle.time, nameEndLine, PERIOD_COLOR);
      if(up >= nBars){
         drawHorizontalLine(lastCandle.high, firstCandle.time, nameBordLine, PERIOD_COLOR);
         return decideToBuyOrToSell(UP, candles[BARS_NUM-1], candles[BARS_NUM]);
      }else if(down >= nBars){
         drawHorizontalLine(lastCandle.low, firstCandle.time, nameBordLine, PERIOD_COLOR);
         return decideToBuyOrToSell(DOWN, candles[BARS_NUM-1], candles[BARS_NUM]);
      }else{
         //drawHorizontalLine(candles[BARS_NUM/2].close, firstCandle.time, nameBordLine, PERIOD_COLOR);
         return MEDIUM;
      }
   }
      
   return MEDIUM;
}

ORIENTATION decideToBuyOrToSell(ORIENTATION orient, MqlRates&  prevCandle, MqlRates& decisionCandle){
   bool isHammer = MEDIUM;
   datetime actualTime = TimeCurrent();
   if(orient == DOWN){
      if(prevCandle.close > decisionCandle.close) {
         isHammer = verifyIfHammer(decisionCandle);
         if(isHammer == DOWN){
            return DOWN;
         }
         drawVerticalLine(actualTime, "Favor"+ IntegerToString(actualTime), clrBlue);
      }else{
         drawVerticalLine(actualTime, "ContraTendencia"+ IntegerToString(actualTime), clrRed);
         return UP;
      }
   }else if(orient == UP){
      if(prevCandle.close < decisionCandle.close) {
         drawVerticalLine(actualTime, "Favor"+ IntegerToString(actualTime), clrBlue);
          isHammer = verifyIfHammer(decisionCandle);
          if(isHammer == UP){
             drawVerticalLine(decisionCandle.time, "UP"+ IntegerToString(decisionCandle.time), clrYellow);
             return UP;
          }
      }else{
         drawVerticalLine(actualTime, "ContraTendencia"+ IntegerToString(actualTime), clrRed);
         return DOWN;
      }
   }
   
   return MEDIUM;
}

ORIENTATION verifyIfHammer(MqlRates& candle){
   double maxAreaHammer = MathAbs(candle.high - candle.low);
   double head = MathAbs(candle.open - candle.close);
   double percMaxAreaHammer = maxAreaHammer * 0.7;
   datetime actualTime = candle.time;
   double stickH, stickL;
   
   if(head >= maxAreaHammer * 0.2){
      //drawVerticalLine(actualTime, "hammer-" + actualTime, HAMMER_COLOR); 
      if(verifyIfOpenBiggerThanClose(candle)){
         stickH = MathAbs(candle.high - candle.open);
         stickL = MathAbs(candle.low - candle.close);
      }else{
         stickH = MathAbs(candle.high - candle.close);
         stickL = MathAbs(candle.low - candle.open);
      }
         
      if(stickH > (stickL + head) && stickH >= percMaxAreaHammer){
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, DOWN); 
         return DOWN;
      }
      
      if(stickL > (stickH + head) && stickL >= percMaxAreaHammer){
         drawArrow(actualTime, "hammer-" + IntegerToString(actualTime), candle.close, UP); 
         return UP;
      }
   }
   
   return MEDIUM;
}