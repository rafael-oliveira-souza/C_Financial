//+------------------------------------------------------------------+
//|                                                          CCI.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"



#include <Trade\Trade.mqh>
CTrade tradeLib;

enum AVERAGE_PONTUATION{
   AVERAGE_0,
   AVERAGE_5,
   AVERAGE_10,
   AVERAGE_15,
   AVERAGE_20,
   AVERAGE_25,
   AVERAGE_30,
};

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

enum NIVEL{
   NVL_1 = 1,
   NVL_2 = 2,
   NVL_3 = 3,
   NVL_4 = 4
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
   ORIENTATION actualOrientation;
   ORIENTATION lastOrientation;
   ORIENTATION secondLastOrientation;
   bool instantiated;
};


struct Averages {
   double a9[];
   double a21[];
   double a80[];
   double a200[];
   double a400[];
   double a600[];
   double m9;
   double m21;
   double m80;
   double m200;
   double m400;
   double m600;
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


input ENUM_TIMEFRAMES PERIOD = PERIOD_H1;
input double VOLUME = 0.01;
input double LOSS_PER_DAY = 0;
input double LOSS_PER_OPERATION = 0;
input double PROFIT_PER_DAY = 0;
input double PROPORTION_TAKE_STOP = 1;
input string SCHEDULE_START_PROTECTION = "00:00";
input string SCHEDULE_END_PROTECTION = "00:00";
input int NUMBER_MAX_ROBOTS = 50;
input int NUMBER_ROBOTS = 10;
input int LOCK_ORDERS_BY_TYPE_IF_LOSS = 3;
 int LOCK_ORDERS_BY_SECONDS = 0;
input int ONLY_OPEN_NEW_ORDER_AFTER = 15;
input double PROTECT_ORDERS_IN_GAIN_BY_POINTS = 300;
input double MOVE_STOP_POINTS = 300;
input bool EXECUTE_CCI = true;
input bool EXECUTE_BOLLINGER_BANDS = true;
 bool EXECUTE_SEQUENCE_CCI = false;
input bool EXECUTE_MACD = true;
 bool EXECUTE_MARTINGALE = false;
input bool CALIBRATE_ORDERS = true;
input bool EXECUTE_EXPONENTIAL_ROBOTS = true;
input bool EXECUTE_EXPONENTIAL_VOLUME = true;
input bool MOVE_STOP = true;
 bool MOVE_TAKE = false;
input int MAX_CCI_VALUE = 100;
input double INITIAL_BALANCE = 350;
 NIVEL NVL_MARTINGALE = NVL_4;
input NIVEL NVL_BOLLINGER = NVL_4;
input NIVEL NVL_CCI = NVL_4;

input int AUTOMATIC_ROBOTS_NUMBER = 5;
input double AUTOMATIC_ROBOTS_STOP = 300;
input double AUTOMATIC_ROBOTS_TAKE = 300;
input int AUTOMATIC_ROBOTS_WIDTH_BUTTON = 150;
input int AUTOMATIC_ROBOTS_HEIGHT_BUTTON = 25;

 int MAX_FORCE_VALUE = 0;
 double MAX_BULLS_AND_BEARS_VALUE = 5;
 ulong MAGIC_NUMBER = 200296;
int WAIT_TICKS = 0;
int WAIT_CANDLES = 0;
double EXPONENTIAL_MULTIPLICATOR_ROBOTS = 1, EXPONENTIAL_MULTIPLICATOR_VOLUME = 1;

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 


double Middle[], Upper[], Lower[], VWAP[], MACD[];
double CCI[], IFORCE[], IBulls[], IBears[], valuePrice = 0;
int handleICCI, handleIForce, handleAverage9, handleAverage21, handleVwap, handleAverage80, handleAverage200, handleAverage400, handleAverage600;
int handleBears, handleBulls, handleBollinger, handleMACD;
ORIENTATION orientMacro = MEDIUM;
double ACTIVE_BALANCE= 0, LAST_BALANCE_ROBOTS = 0, LAST_BALANCE_GOALS = 0, ACTIVE_VOLUME = 0;
double PROFIT_TOTAL= 0, PROFIT_SELL_TOTAL = 0, PROFIT_BUY_TOTAL = 0;
int numberRobotsActive = 0, waitTicks = 0, waitCandlesBollinger = 0, waitCandles = 0, countAverage = 0; 
bool waitNewDay = false, dailyProfitReached = false;
int countRobots = 0, periodAval = 5;
ulong robots[];
datetime startedDatetimeRobot;
bool sellOrdersLocked = true,  buyOrdersLocked = true;
int ultimo = periodAval-1, penultimo = periodAval-2, antipenultimo = periodAval-3, primeiro = 0, segundo = 1, terceiro = 2;
POWER lockBuy = OFF, lockSell = OFF;
bool LOCK_ROBOTS = false, SHOW_BUTTONS = false;

//+------------------------------------------------------------------+
//                                                                          | Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   handleICCI = iCCI(_Symbol,PERIOD,14,PRICE_TYPICAL);
//   handleAverage9 = iMA(_Symbol,PERIOD,9,0,MODE_SMMA,PRICE_CLOSE);
//   handleAverage21 = iMA(_Symbol,PERIOD,21,0,MODE_SMMA,PRICE_CLOSE);
 //  handleAverage80 = iMA(_Symbol,PERIOD,80,0,MODE_SMMA,PRICE_CLOSE);
 //  handleAverage200 = iMA(_Symbol,PERIOD,200,0,MODE_SMMA,PRICE_CLOSE);
 //  handleAverage400 = iMA(_Symbol,PERIOD,400,0,MODE_SMMA,PRICE_CLOSE);
 //  handleAverage600 = iMA(_Symbol,PERIOD,600,0,MODE_SMMA,PRICE_CLOSE);
   handleBollinger = iBands(_Symbol, PERIOD, 20, 0, 2,PRICE_CLOSE);
   handleMACD = iMACD(_Symbol,PERIOD,12, 26, PERIOD,PRICE_CLOSE);
   //handleIForce = iForce(_Symbol,PERIOD,14, MODE_SMA, VOLUME_TICK);
   //handleBears = iBearsPower(_Symbol,PERIOD,14);
   //handleBulls = iBullsPower(_Symbol,PERIOD,14);
   ACTIVE_BALANCE = AccountInfoDouble(ACCOUNT_BALANCE);
   LAST_BALANCE_ROBOTS = ACTIVE_BALANCE;
   LAST_BALANCE_GOALS = ACTIVE_BALANCE;
   ACTIVE_VOLUME = VOLUME;
   numberRobotsActive = NUMBER_ROBOTS;
   startedDatetimeRobot = TimeCurrent();
   initRobots(numberRobotsActive);
   generateButtons();
   return(INIT_SUCCEEDED);
}
  
void OnTick() {
   countRobots = PositionsTotal();
   if(countRobots < numberRobotsActive) {
      waitTicks--;
      if(isNewDay(startedDatetimeRobot)) {
         startedDatetimeRobot = TimeCurrent();
         printf("Novo dia iniciado!");
         waitNewDay = false;
         waitCandles = 0;
         waitTicks = 0;
      }
      
      if(!LOCK_ROBOTS){
         removeLockIfNotExistOrder();
      }
         
      if(!waitNewDay && verifyTimeToProtection()){
         int copiedPrice = CopyRates(_Symbol,PERIOD,0,periodAval,candles);
         if(copiedPrice == periodAval){
            waitNewDay = verifyResultPerDay(startedDatetimeRobot);
            if(hasNewCandle()) {
               showComments();
               waitCandles--;
               waitCandlesBollinger--;
            }
            if(waitCandles <= 0 && waitTicks <= 0) {
               MainCandles mainCandles = generateMainCandles();
               validateAll(mainCandles);
               if(EXECUTE_CCI){
                 executeCCI(mainCandles);
               }
               if(EXECUTE_BOLLINGER_BANDS){
                 executeBollingerBands(mainCandles);
               }
               if(EXECUTE_SEQUENCE_CCI){
              //    executeStrategySequenceFlow(mainCandles);
               }
               if(EXECUTE_MACD){
                  executeMACD(mainCandles);
               }
            }
         }   
      }
   }
}

void executeMACD(MainCandles& mainCandles){
   if(CopyBuffer(handleMACD,0,0,periodAval,MACD) == periodAval) {
      if(!sellOrdersLocked){
         if(MACD[primeiro] > MACD[segundo] && MACD[segundo] > MACD[antipenultimo] &&  MACD[antipenultimo] > MACD[penultimo] &&  MACD[penultimo] > MACD[ultimo]){
            if(MACD[primeiro] > 0 && MACD[segundo] > 0 && MACD[antipenultimo] < 0 && MACD[penultimo] < 0 && MACD[ultimo] < 0){
               if(mainCandles.secondLastOrientation == UP && mainCandles.actualOrientation == DOWN && mainCandles.lastOrientation == DOWN) {
                  double stop = calcPoints(mainCandles.secondLast.high, mainCandles.actual.close, true) ;
                  double take =  stop * 2 * PROPORTION_TAKE_STOP;
                  
                  lockOrderInLoss();
                  calibrateOrdersAndBuyOrSell(DOWN, stop, take);
                  drawHorizontalLine(mainCandles.actual.close, "MACD_DOWN" + IntegerToString(getActualRobot()), clrAntiqueWhite);
               }
            }
         }
      }
      if(!buyOrdersLocked){
         if(MACD[primeiro] < MACD[segundo]  && MACD[segundo] < MACD[antipenultimo] &&  MACD[antipenultimo] < MACD[penultimo] &&  MACD[penultimo] < MACD[ultimo]){
            if(MACD[primeiro] < 0 && MACD[segundo] < 0 && MACD[antipenultimo] > 0 && MACD[penultimo] > 0 && MACD[ultimo] > 0){
               if(mainCandles.secondLastOrientation == DOWN && mainCandles.actualOrientation == UP && mainCandles.lastOrientation == UP) {
                  double stop = calcPoints(mainCandles.secondLast.low, mainCandles.actual.close, true) ;
                  double take =  stop * 2 * PROPORTION_TAKE_STOP;
    
                  lockOrderInLoss();
                  calibrateOrdersAndBuyOrSell(UP, stop, take);
                  drawHorizontalLine(mainCandles.actual.close, "MACD_UP" + IntegerToString(getActualRobot()), clrAntiqueWhite);
               }
            }
         }
      }
   }
}

void executeMartingale(MainCandles& mainCandles, double stop, double take){
   if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval) {
      double actualIdx = CCI[antipenultimo];
      if(sellOrdersLocked == true){
         calibrateOrdersAndBuyMartingale(mainCandles, NVL_1, stop, take);
         if((mainCandles.lastOrientation == DOWN &&  mainCandles.actualOrientation == UP)) {
            calibrateOrdersAndBuyMartingale(mainCandles, NVL_2, stop, take);
            if((mainCandles.actual.close >= mainCandles.last.open )) {
               calibrateOrdersAndBuyMartingale(mainCandles, NVL_3, stop, take);
               if(actualIdx <= -MAX_CCI_VALUE) {
                  calibrateOrdersAndSellMartingale(mainCandles, NVL_4, stop, take);
               }
            }
         }
      }
      if(buyOrdersLocked == true){
         calibrateOrdersAndSellMartingale(mainCandles, NVL_1, stop, take);
         if((mainCandles.lastOrientation == UP &&  mainCandles.actualOrientation == DOWN)) {
            calibrateOrdersAndSellMartingale(mainCandles, NVL_2, stop, take);
            if((mainCandles.actual.close <= mainCandles.last.open )) {
               calibrateOrdersAndSellMartingale(mainCandles, NVL_3, stop, take);
               if(actualIdx >= MAX_CCI_VALUE) {
                  calibrateOrdersAndSellMartingale(mainCandles, NVL_4, stop, take);
               }
            }
         }
      }
   }
}

void executeCCI(MainCandles& mainCandles){
   if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval) {
      double actualIdx = CCI[antipenultimo];
      double lastIdx = CCI[penultimo];
      double secondLastIdx = CCI[ultimo];
      if((mainCandles.secondLastOrientation == UP &&  secondLastIdx >= MAX_CCI_VALUE)) {
         calibrateOrdersAndSellCCI(mainCandles, NVL_1);
         if((mainCandles.lastOrientation == UP &&  lastIdx >= MAX_CCI_VALUE)) {
            calibrateOrdersAndSellCCI(mainCandles, NVL_2);
            if((mainCandles.actualOrientation != UP &&  actualIdx <= MAX_CCI_VALUE)) {
               calibrateOrdersAndSellCCI(mainCandles, NVL_3);
               if((mainCandles.actual.close <= mainCandles.last.low )) {
                  calibrateOrdersAndSellCCI(mainCandles, NVL_4);
               }
            }
         }               
      }
      else if((mainCandles.secondLastOrientation == DOWN &&  secondLastIdx <= -MAX_CCI_VALUE)) {
         calibrateOrdersAndBuyCCI(mainCandles, NVL_1);
         if((mainCandles.lastOrientation == DOWN && lastIdx <= -MAX_CCI_VALUE)) {
            calibrateOrdersAndBuyCCI(mainCandles, NVL_2);
            if((mainCandles.actualOrientation != DOWN &&  actualIdx >= -MAX_CCI_VALUE)) {
               calibrateOrdersAndBuyCCI(mainCandles, NVL_3);
               if((mainCandles.actual.close >= mainCandles.last.high)) {
                  calibrateOrdersAndBuyCCI(mainCandles, NVL_4);
               }
            }
         }               
      }   
   }
}

void calibrateOrdersAndSellMartingale(MainCandles& mainCandles, NIVEL nvl, double stop, double take){ 
   lockOrderInLoss();
   if(NVL_MARTINGALE == nvl) {
      calibrateOrdersAndBuyOrSell(DOWN, stop, take);
      drawHorizontalLine(mainCandles.actual.close, EnumToString(nvl) + "_MARTINGALE_DOWN" + IntegerToString(getActualRobot()), clrPink);
   }
}

void calibrateOrdersAndBuyMartingale(MainCandles& mainCandles, NIVEL nvl, double stop, double take){ 
   lockOrderInLoss();
   if(NVL_MARTINGALE == nvl) {
      calibrateOrdersAndBuyOrSell(UP, stop, take);
      drawHorizontalLine(mainCandles.actual.close, EnumToString(nvl) + "_MARTINGALE_UP" + IntegerToString(getActualRobot()), clrPink);
   }
}


void calibrateOrdersAndSellCCI(MainCandles& mainCandles, NIVEL nvl){ 
   double max = mainCandles.last.high > mainCandles.secondLast.high ? mainCandles.last.high : mainCandles.secondLast.high;
   max = max > mainCandles.actual.high ? max : mainCandles.actual.high;
   double stop = calcPoints(max, mainCandles.actual.close, true);
   double take =  stop * PROPORTION_TAKE_STOP;
 
   lockOrderInLoss();
   if(!sellOrdersLocked && NVL_CCI == nvl) {
      calibrateOrdersAndBuyOrSell(DOWN, stop, take);
      drawHorizontalLine(mainCandles.actual.close, EnumToString(nvl) + "_CCI_DOWN" + IntegerToString(getActualRobot()), clrAquamarine);
   }
}

void calibrateOrdersAndBuyCCI(MainCandles& mainCandles, NIVEL nvl){ 
   double max = mainCandles.last.high > mainCandles.secondLast.high ? mainCandles.last.high : mainCandles.secondLast.high;
   max = max > mainCandles.actual.high ? max : mainCandles.actual.high;
   double stop = calcPoints(max, mainCandles.actual.close, true);
   double take = stop * PROPORTION_TAKE_STOP;
   
   lockOrderInLoss();
   if(!buyOrdersLocked && NVL_CCI == nvl) {
      calibrateOrdersAndBuyOrSell(UP, stop, take);
      drawHorizontalLine(mainCandles.actual.close, EnumToString(nvl) + "_CCI_UP" + IntegerToString(getActualRobot()), clrViolet);
   }
}

void executeBollingerBands(MainCandles& mainCandles){ 
   if(waitCandlesBollinger <= 0) {
      if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval
         && CopyBuffer(handleBollinger, 0, 0, periodAval, Middle) == periodAval
         && CopyBuffer(handleBollinger, 1, 0, periodAval, Upper) == periodAval
         && CopyBuffer(handleBollinger, 2, 0, periodAval, Lower) == periodAval) {
         if(getCandleOrientantion(candles[antipenultimo]) == UP  && candles[antipenultimo].close >= Upper[antipenultimo] ) {
            calibrateOrdersAndSellBollinger(mainCandles, NVL_1);
            if(getCandleOrientantion(candles[penultimo]) == UP  && candles[penultimo].close >= Upper[penultimo] ) {
               calibrateOrdersAndSellBollinger(mainCandles, NVL_2);
               if(CCI[antipenultimo] >= MAX_CCI_VALUE && CCI[penultimo] >= MAX_CCI_VALUE && CCI[ultimo] <= MAX_CCI_VALUE) {
                  calibrateOrdersAndSellBollinger(mainCandles, NVL_3);
                  if(mainCandles.actualOrientation == DOWN && mainCandles.actual.close <= Upper[ultimo]) {
                     calibrateOrdersAndSellBollinger(mainCandles, NVL_4);
                  } 
               }
            }              
         }
         else if(getCandleOrientantion(candles[antipenultimo]) == DOWN  && candles[antipenultimo].close <= Lower[antipenultimo] ) {
            calibrateOrdersAndBuyBollinger(mainCandles, NVL_1);
            if(getCandleOrientantion(candles[penultimo]) == DOWN  && candles[penultimo].close <= Lower[penultimo]) {
               calibrateOrdersAndBuyBollinger(mainCandles, NVL_2);
               if( CCI[antipenultimo] <= -MAX_CCI_VALUE  && CCI[penultimo] <= -MAX_CCI_VALUE  && CCI[ultimo] >= -MAX_CCI_VALUE) {
                  calibrateOrdersAndBuyBollinger(mainCandles, NVL_3);
                  if(mainCandles.actualOrientation == UP && mainCandles.actual.close >= Lower[ultimo]) {
                     calibrateOrdersAndBuyBollinger(mainCandles, NVL_4);
                     return;
                  }  
               }             
            }
         }  
      }
   }
}

void calibrateOrdersAndSellBollinger(MainCandles& mainCandles, NIVEL nvl){ 
   double percent = 0.7;
   double stop = calcPoints(Upper[ultimo], Middle[ultimo], true)* percent;
   double take = stop * PROPORTION_TAKE_STOP;
 
   lockOrderInLoss();
   if(!sellOrdersLocked && NVL_BOLLINGER == nvl) {
      calibrateOrdersAndBuyOrSell(DOWN, stop, take);   
      drawHorizontalLine(mainCandles.actual.close, EnumToString(nvl) + "_BLG_DOWN" + IntegerToString(getActualRobot()), clrYellow);
      waitCandlesBollinger = 0;
   }
}

void calibrateOrdersAndBuyBollinger(MainCandles& mainCandles, NIVEL nvl){ 
   double percent = 0.7;
   double stop = calcPoints(Lower[ultimo], Middle[ultimo], true)* percent;
   double take = stop * PROPORTION_TAKE_STOP;
 
   lockOrderInLoss();
   if(!buyOrdersLocked && NVL_BOLLINGER == nvl) {
      calibrateOrdersAndBuyOrSell(UP, stop, take);
      drawHorizontalLine(mainCandles.actual.close, EnumToString(nvl) + "_BLG_UP" + IntegerToString(getActualRobot()), clrGreen);
      waitCandlesBollinger = 0;
   }
}

void executeStrategySequenceFlow(MainCandles& mainCandles){
   if(mainCandles.secondLastOrientation == UP && mainCandles.lastOrientation == UP) {
      bool bodyIsGreater = bodyGreaterThanWick(mainCandles.secondLast);
      bool bodyIsGreaterLast = bodyGreaterThanWick(mainCandles.last);
      double max = mainCandles.secondLast.low < mainCandles.last.low ? mainCandles.secondLast.low : mainCandles.last.low;
      double stop = calcPoints(max, mainCandles.actual.close, true) ;
      double take = calcPoints(mainCandles.last.open, mainCandles.last.close, true) ;
      lockOrderInLoss();
      if(!buyOrdersLocked && bodyIsGreater && bodyIsGreaterLast) {
         calibrateOrdersAndBuyOrSell(UP, stop, take);
         drawHorizontalLine(mainCandles.actual.close, "_SEQUENCE_UP" + IntegerToString(getActualRobot()), clrAntiqueWhite);
      }
   }else if(mainCandles.secondLastOrientation == DOWN && mainCandles.lastOrientation == DOWN) {
      bool bodyIsGreater = bodyGreaterThanWick(mainCandles.secondLast);
      bool bodyIsGreaterLast = bodyGreaterThanWick(mainCandles.last);
      double max = mainCandles.secondLast.high < mainCandles.last.high ? mainCandles.secondLast.high : mainCandles.last.high;
      double stop = calcPoints(max, mainCandles.actual.close, true) ;
      double take = calcPoints(mainCandles.last.open, mainCandles.last.close, true) ;
      lockOrderInLoss();
      if(!sellOrdersLocked  && bodyIsGreater && bodyIsGreaterLast) {
         calibrateOrdersAndBuyOrSell(DOWN, stop, take);
         drawHorizontalLine(mainCandles.actual.close, "_SEQUENCE_DOWN" + IntegerToString(getActualRobot()), clrAntiqueWhite);
      }
   }
}

bool validateSequence(MqlRates& candlesV[], int start, int end, bool isUp) {
   double media1 = 0;
   bool isSequence = true;
   for(int i = start; i < end; i++) {
      media1 = bodyGreaterThanWick(candlesV[i]);
     // 
      if(isUp) {
         if(candlesV[i].open  > candlesV[i].close ){
           isSequence = false;
         }
      }else {
         if(candlesV[i].open  < candlesV[i].close){
           isSequence = false;
         }
      }
   }
   
   return isSequence;
}

double calcProportionalLockedOrders() {
   if(EXECUTE_EXPONENTIAL_ROBOTS && NUMBER_ROBOTS < numberRobotsActive){
      return round(NormalizeDouble(numberRobotsActive * 0.3, 2));
   }

   return LOCK_ORDERS_BY_TYPE_IF_LOSS;
}

void validateAll(MainCandles& mainCandles){
     
   if(countRobots > 0 && PROTECT_ORDERS_IN_GAIN_BY_POINTS > 0) {
      protectOrderInGain(PROTECT_ORDERS_IN_GAIN_BY_POINTS);
   }
   
   executeExponentials();
   for(int position = PositionsTotal(); position >= 0; position--)  {
      if(hasPositionOpen(position)){
         ulong ticket = PositionGetTicket(position);
         PositionSelectByTicket(ticket);
         calculateProfit();
         
         if(MOVE_STOP) {
            moveStopPerPoint(position, ticket, MOVE_STOP_POINTS);
         }
         
         if(MOVE_TAKE){
          //  moveTakePercent(position, ticket, MOVE_STOP_POINTS, MOVE_TAKE_PERCENT);
         }
         // calibrateOrdersInLoss(mainCandles, position, ticket);
      }
   }
}

void exponentialRobots(MainCandles& mainCandles){
   ulong ticket = PositionGetTicket(0);
   PositionSelectByTicket(ticket);
   double stopLoss = PositionGetDouble(POSITION_SL);
   double tpPrice = PositionGetDouble(POSITION_TP);
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double current = PositionGetDouble(POSITION_PRICE_CURRENT);
   double points = calcPoints(open, current, true);
   double takePoints = calcPoints(open, tpPrice, true);
   double stopPoints = calcPoints(open, stopLoss, true);
   double midPoints = takePoints * 0.3;
   if(!buyOrdersLocked && PROFIT_BUY_TOTAL > 0 && points > midPoints){
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
         calibrateOrdersAndBuyOrSell(UP, 100, 100, false);
      }
   }
   if(!sellOrdersLocked && PROFIT_SELL_TOTAL > 0 && points > midPoints){
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
         calibrateOrdersAndBuyOrSell(DOWN, 100, 100, false);
      }
   }
}

void calibrateOrdersInLoss(MainCandles& mainCandles, int position, ulong ticket, double points = 100){
   double stopLoss = PositionGetDouble(POSITION_SL);
   double tpPrice = PositionGetDouble(POSITION_TP);
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double current = PositionGetDouble(POSITION_PRICE_CURRENT);
   double lossPoints = calcPoints(open, current, true);
   double takePoints = calcPoints(open, tpPrice, true);
   double stopPoints = calcPoints(open, stopLoss, true);
   double midStopPoints = stopPoints * 0.5;
   if(sellOrdersLocked || buyOrdersLocked){
      if((PROFIT_SELL_TOTAL < 0 || PROFIT_BUY_TOTAL < 0) && lossPoints > midStopPoints) {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
           // closeBuyOrSell(position, robots[position]);
            if(EXECUTE_MARTINGALE){
             // //executeMartingale(mainCandles, stopPoints, takePoints);
              calibrateOrdersAndBuyOrSell(UP, 100, 100, false);
            }
         }
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
           // closeBuyOrSell(position, robots[position]);
            if(EXECUTE_MARTINGALE){
             // executeMartingale(mainCandles, stopPoints, takePoints);
              calibrateOrdersAndBuyOrSell(DOWN, 100, midStopPoints, false);
            }
         }
      }
   }
}

void lockOrderInLoss(){
   int sellOrdersInLoss = 0, buyOrdersInLoss = 0;
   double lockOrdersByTipeQtd = calcProportionalLockedOrders();
   double sumBuys = 0, sumSells = 0;
   
   if(lockOrdersByTipeQtd > 0){
      long now = (long)TimeCurrent();
      for(int position = PositionsTotal(); position >= 0; position--)  {
         //ulong magicNumber = robots[position];
         if(hasPositionOpen(position)){
            ulong ticket = PositionGetTicket(position);
            PositionSelectByTicket(ticket);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double current = PositionGetDouble(POSITION_PRICE_CURRENT);
            double open = PositionGetDouble(POSITION_PRICE_OPEN);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double stopLoss = PositionGetDouble(POSITION_SL);
            double tpPrice = PositionGetDouble(POSITION_TP);
            double points = calcPoints(open, tpPrice, true) * 0.01;
            
            
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
              sumBuys = sumBuys + profit;
            }
            else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
              sumSells = sumSells + profit;
            }
            // 
            if(profit < 0  && MathAbs(profit) >= points && (LOCK_ORDERS_BY_SECONDS <= 0 || verifyIfSecondsIsBetterThanTimeFromPosition(now, position, LOCK_ORDERS_BY_SECONDS))){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                 buyOrdersInLoss++;
               }
               else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                 sellOrdersInLoss++;
               }
            }
         }
      }
      //&& sumBuys < 0
      if(buyOrdersInLoss >= lockOrdersByTipeQtd ) {
         Print("Is Locked to " + EnumToString(POSITION_TYPE_BUY));
         buyOrdersLocked = true;
      }
      // && sumSells < 0
      if(sellOrdersInLoss >= lockOrdersByTipeQtd) {
        Print("Is Locked to " + EnumToString(POSITION_TYPE_SELL));
        sellOrdersLocked = true;
      }
   }
   
}


void removeLockIfNotExistOrder(){
   if(sellOrdersLocked == true || buyOrdersLocked == true){
      int sellOrdersInLoss = 0, buyOrdersInLoss = 0;
      for(int position = PositionsTotal()-1; position >= 0; position--)  {
         if(hasPositionOpen(position)){
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
              buyOrdersInLoss++;
            }
            else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
              sellOrdersInLoss++;
            }
         }
      }
   
      if(buyOrdersLocked == true && buyOrdersInLoss == 0) {
         buyOrdersLocked = false;
      }
      else if(sellOrdersLocked == true && sellOrdersInLoss == 0) {
         sellOrdersLocked = false;
      }
   }
   
   if(lockBuy == ON){
      buyOrdersLocked = true;
   }
   
   if(lockSell == ON){
      sellOrdersLocked = true;
   }
}

void calibrateOrdersAndBuyOrSell(ORIENTATION orient, double stopLossPoints, double take, bool ignoreRobotsNumber = false){
   double volume = ACTIVE_VOLUME;
   if(LOSS_PER_OPERATION > 0){
      if(CALIBRATE_ORDERS){
         while(LOSS_PER_OPERATION < (stopLossPoints * volume)) {
            volume = volume - 0.01;
         }
      }
      if(LOSS_PER_OPERATION > 0 && LOSS_PER_OPERATION < (stopLossPoints * volume)) {
         return;
      }
   }
   
   int lastPosition = PositionsTotal()-1;
   long now = (long)TimeCurrent();
   if(verifyIfSecondsIsBetterThanTimeFromPosition(now, lastPosition, ONLY_OPEN_NEW_ORDER_AFTER)) {
      toBuyOrToSell(orient, volume, stopLossPoints, take, getActualRobot(), ignoreRobotsNumber);
   }
}

double calculateBullsAndBearsPower(double bullsPower, double bearsPower, bool absValue = true){
   return absValue ? (MathAbs(bullsPower) + MathAbs(bearsPower)) : (bullsPower + bearsPower);
}

ulong getActualRobot(){
   if(ArraySize(robots) > countRobots) {
      return robots[countRobots];
   }else {
      Print("Number max robots reached");
      return NULL;
   }
}

//+------------------------------------------------------------------+
void showComments(){
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   Comment(
         " Total de robôs Disponiveis: ", (numberRobotsActive - countRobots),
         " Total de robôs ativos: ", (countRobots),
         " Volume: ", ACTIVE_VOLUME,
         " Saldo: ", DoubleToString(ACTIVE_BALANCE + profit, 2),
         " Lucro Atual: ", DoubleToString(profit, 2),
         " Lucro de Vendas Atual: ", DoubleToString(PROFIT_SELL_TOTAL, 2),
         " Lucro de Compras Atual: ", DoubleToString(PROFIT_BUY_TOTAL, 2),
         " Robos Travados: ", DoubleToString(calcProportionalLockedOrders(), 2));
}

ORIENTATION getCandleOrientantion(MqlRates& candle){
   if(candle.close > candle.open) {
      return UP;
   }
   else if(candle.close < candle.open) {
      return DOWN;
   }
   
   return MEDIUM;
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

bool realizeDeals(TYPE_NEGOCIATION typeDeals, double volume, double stopLoss, double takeProfit, ulong magicNumber, bool ignoreRobotsNumber = false){
   if(typeDeals != NONE){
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
      if((ignoreRobotsNumber || countRobots <= numberRobotsActive) && hasPositionOpenWithMagicNumber(countRobots, magicNumber) == false) {
         if(typeDeals == BUY){ 
            toBuy(volume, borders.min, borders.max);
         }
         else if(typeDeals == SELL){
            toSell(volume, borders.min, borders.max);
         }
         
         if(verifyResultTrade()){
            tradeLib.SetExpertMagicNumber(magicNumber);
            Print("MAGIC NUMBER: " + IntegerToString(magicNumber));
            countRobots = PositionsTotal();
            waitTicks = WAIT_TICKS;
            waitCandles = WAIT_CANDLES;
            return true;
         }
       }
    }
    
    return false;
}

void closeAll(){
   for(int position = countRobots; position >= 0; position--)  {
      closeBuyOrSell(position, robots[position]);
   }
}

void closeBuyOrSell(int position, ulong magicNumber){
   if(hasPositionOpenWithMagicNumber(position, magicNumber)){
      ulong ticket = PositionGetTicket(position);
      tradeLib.PositionClose(ticket);
      countRobots = PositionsTotal();
      if(verifyResultTrade()){
         Print("Negociação concluída.");
      }
   }
}

bool toBuyOrToSell(ORIENTATION orient, double volume, double stopLoss, double takeProfit, ulong magicNumber, bool ignoreRobotsNumber = false){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   return realizeDeals(typeDeal, volume, stopLoss, takeProfit, magicNumber, ignoreRobotsNumber);
}

bool hasPositionOpen(int position){
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


bool hasPositionOpenWithMagicNumber(int position, ulong magicNumberRobot){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(magicNumber == magicNumberRobot){
         return true;
      }
   }
   
   return false;
   
}

void closePositionInProfit(){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      ulong ticket = PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(i, magicNumber) ){
          double profit = PositionGetDouble(POSITION_PROFIT);
          if(profit > 0){
            closeBuyOrSell(i, magicNumber);
          }
      } 
   }
}

bool verifyMagicNumber(int position = 0, ulong magicNumberRobot = 0){
   if(hasPositionOpen(position)){
      if(magicNumberRobot == MAGIC_NUMBER){
         return true;
      }
   }
   return false;
   
}

bool hasNewCandle(){
   static datetime lastTime = 0;
   
   datetime lastBarTime = (datetime)SeriesInfoInteger(Symbol(),PERIOD,SERIES_LASTBAR_DATE);
   
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

bool verifyTimeToProtection(){
   if(timeToProtection(SCHEDULE_START_PROTECTION, SCHEDULE_END_PROTECTION)){
     // Print("Horario de proteção ativo");
      return false;
   }
   return true;
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


ORIENTATION getOrientationPerCandles(MqlRates& prev, MqlRates& actual){
   if(actual.open > prev.open){
      return UP;
   }else if(actual.open < prev.open){
      return DOWN;
   }
   
   return MEDIUM;
}

Averages generateMainAverages() {
   int periodAverages = 9;
   Averages averages;
   
   if(CopyBuffer(handleAverage9,0,0,periodAverages,averages.a9) == periodAverages
      && CopyBuffer(handleAverage21,0,0,periodAverages,averages.a21) == periodAverages
      && CopyBuffer(handleAverage80,0,0,periodAverages,averages.a80) == periodAverages
      && CopyBuffer(handleAverage200,0,0,periodAverages,averages.a200) == periodAverages
      && CopyBuffer(handleAverage400,0,0,periodAverages,averages.a400) == periodAverages
      && CopyBuffer(handleAverage600,0,0,periodAverages,averages.a600) == periodAverages){
      averages.m9 = getAverage(averages.a9);
      averages.m21 = getAverage(averages.a21);
      averages.m80 = getAverage(averages.a80);
      averages.m200 = getAverage(averages.a200);
      averages.m400 = getAverage(averages.a400);
      averages.m600 = getAverage(averages.a600);
   }
   
   return averages;
}

MainCandles generateMainCandles(){
   MainCandles mainCandles;
   int copiedPrice = CopyRates(_Symbol,PERIOD,0,periodAval,candles);
   if(copiedPrice == periodAval){
      mainCandles.actual = candles[ultimo];
      mainCandles.last = candles[penultimo];
      mainCandles.secondLast = candles[antipenultimo];
      mainCandles.actualOrientation = getCandleOrientantion( mainCandles.actual);
      mainCandles.lastOrientation = getCandleOrientantion( mainCandles.last);
      mainCandles.secondLastOrientation = getCandleOrientantion( mainCandles.secondLast);
      mainCandles.instantiated = true;
   }else{
      mainCandles.instantiated = false;
   }
   
   return mainCandles;
}

bool isNewDay(datetime date){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(date, structDate);
   
   if((structActual.day_of_year - structDate.day_of_year) > 0){
      return true;
   }else{
      return false;
   }
}

double calcPoints(double val1, double val2, bool absValue = true){
   if(absValue){
      return MathAbs(val1 - val2) / _Point;
   }else{
      return (val1 - val2) / _Point;
   }
}

bool verifyIfSecondsIsBetterThanTimeFromPosition( long now, int position, int seconds) {
   if(position >= 0 && hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      long positionDatetime = PositionGetInteger(POSITION_TIME);
      return seconds <= ((now - positionDatetime));
   }
   
   return true;
}

double getDayProfit(datetime date) {
   double dayprof = 0.0;
   datetime end = StringToTime(TimeToString (date, TIME_DATE));
   datetime start = end - PeriodSeconds( PERIOD_D1 );
   HistorySelect(start,end);
   int TotalDeals = HistoryDealsTotal();
   for(int i = 0; i < TotalDeals; i++)  {
      ulong Ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(Ticket,DEAL_ENTRY) == DEAL_ENTRY_OUT)  {
         double LatestProfit = HistoryDealGetDouble(Ticket, DEAL_PROFIT);
         dayprof += LatestProfit;
      }
   }
   return dayprof;
}

//return true se atingiu o ganho ou perda diario;
bool verifyResultPerDay(datetime date){
   double profit = getDayProfit(date);
   if(MathAbs(profit) > 0){
      if(LOSS_PER_DAY > 0 && PROFIT_PER_DAY > 0){
         if(profit > PROFIT_PER_DAY){
            printf("Lucro diario excedido: %s.", DoubleToString(profit));
            return true;
         }
         if((-profit) > LOSS_PER_DAY){
            printf("Lucro diario excedido: %s.", DoubleToString(profit));
            return true;
         }
      }
   }
   
   return false;
}

void protectOrderInGain(double points){
   if(points > 0) {
      for(int position = PositionsTotal(); position >= 0; position--)  {
         ulong magicNumber = robots[position];
         if(hasPositionOpenWithMagicNumber(position, magicNumber)){
            ulong ticket = PositionGetTicket(position);
            PositionSelectByTicket(ticket);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double newTake = PositionGetDouble(POSITION_TP);
            double newSl = PositionGetDouble(POSITION_SL);
            double pointsGain = calcPoints(entryPrice, currentPrice, true);
            double pointsToTake = calcPoints(newTake, currentPrice, true);
            double pointsToStop = calcPoints(newSl, currentPrice, true);
            
            if( profit > 0 && (pointsGain >= points)){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && newSl <= entryPrice){
                   newSl = entryPrice + (points * 0.2 * _Point);
                  tradeLib.PositionModify(ticket, newSl, newTake);
                  if(verifyResultTrade()){
                     Print("Ordem Protegida");
                  }
               }
               else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && newSl >= entryPrice){
                   newSl = entryPrice - (points * 0.2 * _Point);
                  tradeLib.PositionModify(ticket, newSl, newTake);
                  if(verifyResultTrade()){
                     Print("Ordem Protegida");
                  }
               }
            }
         }
      }
   }
}  

void moveTakePercent(int position , ulong ticket, double points, double takePercent){
   if(points > 0 && takePercent > 0) {
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double profit = PositionGetDouble(POSITION_PROFIT);
      double take = PositionGetDouble(POSITION_TP);
      double pointsGain = calcPoints(entryPrice, currentPrice, true);
      double pointsToTake = calcPoints(take, currentPrice, true);
      
     if( profit > 0 && pointsGain >= (pointsToTake * takePercent / 100)){
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
             double newTake = take + (points * _Point);
             double newSl = currentPrice - (points * _Point);
             tradeLib.PositionModify(ticket, newSl, newTake);
             if(verifyResultTrade()){
               Print("Take Avancado");
             }  
         }
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
             double newTake = take - (points * _Point);
             double newSl = currentPrice + (points * _Point);
             tradeLib.PositionModify(ticket, newSl, newTake);
             if(verifyResultTrade()){
               Print("Take Avancado");
             }   
         }
      }
   }
}  

void moveAllTakePerPoint(double points, ENUM_POSITION_TYPE type = NULL){
   for(int position = PositionsTotal(); position >= 0; position--)  {
      ulong magicNumber = robots[position];
      if(hasPositionOpen(position)){
         ulong ticket = PositionGetTicket(position);
         PositionSelectByTicket(ticket);
          moveTakePerPoint(position, ticket, points);
      }
   }
}  

void moveTakePerPoint(int position, ulong ticket, double points, ENUM_POSITION_TYPE type = NULL){
   if(points > 0) {
      double newTP = PositionGetDouble(POSITION_TP);
      double slPrice = PositionGetDouble(POSITION_SL);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      
      if((type == NULL && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ) ||  PositionGetInteger(POSITION_TYPE) == type){
         if(newTP < entryPrice){
            newTP = entryPrice;
         }
         tradeLib.PositionModify(ticket, slPrice,newTP);
      }
      else if((type == NULL && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ) ||  PositionGetInteger(POSITION_TYPE) == type ){
         if(newTP > entryPrice){
            newTP = entryPrice;
         }
         tradeLib.PositionModify(ticket, slPrice,newTP);
      }
   }
}  

void moveAllStopPerPoint(double points, ENUM_POSITION_TYPE type = NULL){
   for(int position = PositionsTotal(); position >= 0; position--)  {
      ulong magicNumber = robots[position];
      if(hasPositionOpen(position)){
         ulong ticket = PositionGetTicket(position);
         PositionSelectByTicket(ticket);
          moveStopPerPoint(position, ticket, points);
      }
   }
}  

void moveStopPerPoint(int position, ulong ticket, double points, ENUM_POSITION_TYPE type = NULL){
   if(points > 0) {
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double profit = PositionGetDouble(POSITION_PROFIT);
      double tpPrice = PositionGetDouble(POSITION_TP);
      double slPrice = PositionGetDouble(POSITION_SL);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double pointsGain = calcPoints(entryPrice, currentPrice, true);
      
      if(profit > 0 && pointsGain >= points) {
         if((type == NULL && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ) ||  PositionGetInteger(POSITION_TYPE) == type){
            double newSl = slPrice + (points * _Point);
            if( newSl > slPrice && newSl < currentPrice){
               tradeLib.PositionModify(ticket, newSl,tpPrice);
               if(verifyResultTrade()){
                  Print("Stop movido");
               }
            }
         }
         else if((type == NULL && PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ) ||  PositionGetInteger(POSITION_TYPE) == type ){
            double newSl = slPrice - (points * _Point);
            if( newSl < slPrice && newSl > currentPrice){
               tradeLib.PositionModify(ticket, newSl,tpPrice);
               if(verifyResultTrade()){
                  Print("Stop movido");
               }
            }
         }
      }
   }
}  

void closePositionByType(ENUM_POSITION_TYPE type, int i){
   if(hasPositionOpen(i)){
      ulong ticket = PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(i, magicNumber) && PositionGetInteger(POSITION_TYPE) == type){
            closeBuyOrSell(i, magicNumber);
      }
   }
}


void closeAllPositionsByType(ENUM_POSITION_TYPE type, int qtd = 0){
   int pos = PositionsTotal()-1;
   
   if(qtd > 0){
      pos = qtd;   
   }
   
   for(int i = pos; i >= 0; i--)  {
      closePositionByType(type, i);
   }
}

bool bodyGreaterThanWick(MqlRates& candle){
   double body = calcPoints(candle.close, candle.open, true);
   double wick = MathAbs(body- calcPoints(candle.low, candle.high, true));
   return body >= wick;
}

void instanciateBorder(BordersOperation& borders){
     borders.max = 0;
     borders.min = 0;
     borders.central = 0;
     borders.instantiated = false;
     borders.orientation = MEDIUM;
}

double getAverage(double& averages[]) {
   double average = 0;
   int qtd = ArraySize(averages);
   for(int i = 0; i < qtd; i++) {
      average += averages[i];
   }

   return average / qtd;
}

bool inInterval(double& averages[], double value) {
   bool exist = false;
   int qtd = ArraySize(averages);
   for(int i = 0; i < qtd; i++) {
      if( averages[i] == value) {
         exist = true;
      }
   }

   return exist;
}

void executeExponentials() {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double initialBalance = INITIAL_BALANCE;
   int mult = 0;
   
   while(initialBalance < balance){
      initialBalance += INITIAL_BALANCE;
      mult++;
   }
   
   if(EXECUTE_EXPONENTIAL_VOLUME) {
      double minimunVolume = 0.01;
      double adicionalVolume = minimunVolume * mult;
      ACTIVE_VOLUME = NormalizeDouble((VOLUME + adicionalVolume), 2);
   }
   
   if(EXECUTE_EXPONENTIAL_ROBOTS) {
      numberRobotsActive = NUMBER_ROBOTS + mult;
      initRobots(numberRobotsActive);
   }  
}

void calculateProfit(){
   PROFIT_TOTAL = 0;
   PROFIT_SELL_TOTAL = 0;
   PROFIT_BUY_TOTAL = 0;
   double profit = PositionGetDouble(POSITION_PROFIT);
   PROFIT_TOTAL += profit;
   if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
      PROFIT_BUY_TOTAL += profit;
   }
   else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
      PROFIT_SELL_TOTAL += profit;
   }
}

void initRobots(int numRobots) {
   ArrayResize(robots, numRobots);
   for(int i = 0; i < numRobots; i++)  {
      robots[i] = MAGIC_NUMBER; 
   }
}

void drawHorizontalLine(double price, string nameLine, color indColor){
   long charId = StringToInteger(_Symbol);
   ObjectCreate(charId,nameLine,OBJ_HLINE,0,0,price);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
   ObjectMove(charId,nameLine,0,0,price);
}

void drawVerticalLine(datetime time, string nameLine, color indColor){
   long charId = StringToInteger(_Symbol);
   ObjectCreate(charId,nameLine,OBJ_VLINE,0,time,0);
   ObjectSetInteger(0,nameLine,OBJPROP_COLOR,indColor);
   ObjectSetInteger(0,nameLine,OBJPROP_WIDTH,1);
}

void deleteButton(string nameLine){
   long charId = StringToInteger(_Symbol);
   ObjectDelete(charId, nameLine);
}

void createButton(string nameLine, int xx, int yy, int largura, int altura, int canto, int tamanho, string fonte, string text, long corTexto, long corFundo, long corBorda, bool oculto){
   long charId = StringToInteger(_Symbol);
   ObjectCreate(charId,nameLine,OBJ_BUTTON,0,0,0);
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

void generateButtons(){
         int larguraMin = 20, distanciaLargura = 210, distanciaLargura1 = larguraMin, distanciaLargura2 = distanciaLargura1+distanciaLargura, distanciaLargura3 = distanciaLargura2 + distanciaLargura;
         int alturaMax = 300,  distanciaAltura = 30, fontSize = 9;
        createButton("btnShowButtons2", larguraMin, alturaMax+distanciaAltura, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, 9, "Arial","Exibir Botoes", clrWhite, clrGreen, clrGreen, false);
      if(SHOW_BUTTONS){
         createButton("btnCloseSell", distanciaLargura1, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Fechar Vendas", clrWhite, clrRed, clrRed, false);
         createButton("btnCloseAll", distanciaLargura2, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
         createButton("btnCloseBuy", distanciaLargura3, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Fechar Compras", clrWhite, clrRed, clrRed, false);
         
         alturaMax -= distanciaAltura;
         createButton("btnCloseProfit", distanciaLargura1, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Fechar com lucro.", clrWhite, clrRed, clrRed, false);
         createButton("btnBuy", distanciaLargura2, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Criar " + IntegerToString(AUTOMATIC_ROBOTS_NUMBER) +" Robôs de Compra", clrWhite, clrBlue, clrBlue, false);
         createButton("btnSell", distanciaLargura3, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Criar " + IntegerToString(AUTOMATIC_ROBOTS_NUMBER) +" Robôs de Venda", clrWhite, clrBlue, clrBlue, false);

         alturaMax -= distanciaAltura;
         createButton("btnLockBuy", distanciaLargura1, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Travar Comprar", clrWhite, pressButtonColor(lockBuy == OFF), pressButtonColor(lockBuy == OFF), false);
         createButton("btnLockSell", distanciaLargura2, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Travar Venda", clrWhite, pressButtonColor(lockSell == OFF), pressButtonColor(lockSell == OFF), false);
         createButton("btnLockRobots", distanciaLargura3, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Travar robôs", clrWhite, pressButtonColor(!LOCK_ROBOTS),  pressButtonColor(!LOCK_ROBOTS), false);
                 
         alturaMax -= distanciaAltura;
         createButton("btnDoubleVol", distanciaLargura1, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Multiplicar Volume por 2", clrWhite, clrBlue, clrBlue, false);
         createButton("btnDivVol", distanciaLargura2, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Dividir Volume por 2", clrWhite, clrBlue, clrBlue, false);
         createButton("btnResetVol", distanciaLargura3, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Resetar Volume", clrWhite, clrBlue, clrBlue, false);
         
         alturaMax -= distanciaAltura;
         createButton("btnMoveStop", distanciaLargura1, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "Proteger Negociações", clrWhite, clrGreen, clrGreen, false);
         createButton("btnUpTakeBuy", distanciaLargura2, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "+" + IntegerToString((int)AUTOMATIC_ROBOTS_TAKE) + " Pts Take na Compra", clrWhite, clrGreen, clrGreen, false);
         createButton("btnDownTakeBuy", distanciaLargura3, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "-" + IntegerToString((int)AUTOMATIC_ROBOTS_TAKE) + " Pts Take na Compra", clrWhite, clrGreen, clrGreen, false);
         
         alturaMax -= distanciaAltura;
         createButton("btnUpStopBuy", distanciaLargura1, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "+" + IntegerToString((int)AUTOMATIC_ROBOTS_STOP) + "  Pts Stop na Compra", clrWhite, clrGreen, clrGreen, false);
         createButton("btnDownStopBuy", distanciaLargura2, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "-" + IntegerToString((int)AUTOMATIC_ROBOTS_STOP) + " Pts Stop na Compra", clrWhite, clrGreen, clrGreen, false);
         createButton("btnUpTakeSell", distanciaLargura3, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial","+" + IntegerToString((int)AUTOMATIC_ROBOTS_TAKE) + " Pts Take na Venda", clrWhite, clrGreen, clrGreen, false);
         
         alturaMax -= distanciaAltura;
         createButton("btnDownTakeSell", distanciaLargura1, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "-" + IntegerToString((int)AUTOMATIC_ROBOTS_TAKE) + " Pts Take na Venda", clrWhite, clrGreen, clrGreen, false);
         createButton("btnUpStopSell", distanciaLargura2, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial", "+" + IntegerToString((int)AUTOMATIC_ROBOTS_STOP) + "  Pts Stop na Venda", clrWhite, clrGreen, clrGreen, false);
         createButton("btnDownStopSell", distanciaLargura3, alturaMax, AUTOMATIC_ROBOTS_WIDTH_BUTTON, AUTOMATIC_ROBOTS_HEIGHT_BUTTON, CORNER_LEFT_LOWER, fontSize, "Arial","-" + IntegerToString((int)AUTOMATIC_ROBOTS_STOP) + " Pts Stop na Venda", clrWhite, clrGreen, clrGreen, false);
  
      }else{
         deleteButton("btnCloseSell");
         deleteButton("btnCloseAll");
         deleteButton("btnCloseBuy");
         deleteButton("btnCloseProfit");
         deleteButton("btnBuy");
         deleteButton("btnSell");
         deleteButton("btnDoubleVol");
         deleteButton("btnDivVol");
         deleteButton("btnResetVol");
         deleteButton("btnLockBuy");
         deleteButton("btnLockSell");
         deleteButton("btnLockRobots");
         deleteButton("btnMoveStop");
         deleteButton("btnUpTakeBuy");
         deleteButton("btnDownTakeBuy");
         deleteButton("btnUpStopBuy");
         deleteButton("btnDownStopBuy");
         deleteButton("btnUpTakeSell");
         deleteButton("btnDownTakeSell");
         deleteButton("btnUpStopSell");
         deleteButton("btnDownStopSell");
      }
}

color pressButtonColor(bool var, color primary = clrBlue, color secundary =  clrBlueViolet){
   return (var == true ? primary : secundary);
}

            
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
   // Fechar negociacões
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "btnShowButtons2"){
         SHOW_BUTTONS = !SHOW_BUTTONS;
         generateButtons();
      }
      if(sparam == "btnCloseBuy"){
         closeAllPositionsByType(POSITION_TYPE_BUY, 0);
      }
      if(sparam == "btnCloseSell"){
         closeAllPositionsByType(POSITION_TYPE_SELL, 0);
      }
      
      if(sparam == "btnCloseAll"){
         closeAll();
      }
      
      if(sparam == "btnMoveStop"){
         int pos = PositionsTotal() - 1;
         for(int i = pos; i >= 0; i--)  {
            protectOrderInGain(AUTOMATIC_ROBOTS_STOP);
         }
      }
      
      if(sparam == "btnBuy"){
         ulong magic = MAGIC_NUMBER + 6000;
         for(int i = 0; i < NUMBER_ROBOTS; i++){
            magic = magic + i;
            realizeDeals(BUY, VOLUME, AUTOMATIC_ROBOTS_STOP, AUTOMATIC_ROBOTS_TAKE, MAGIC_NUMBER);
         }
      }
      
      if(sparam == "btnSell"){
         ulong magic = MAGIC_NUMBER + 6000;
         for(int i = 0; i < NUMBER_ROBOTS; i++){
            magic = magic + i;
            realizeDeals(SELL, VOLUME, AUTOMATIC_ROBOTS_STOP, AUTOMATIC_ROBOTS_TAKE, MAGIC_NUMBER);
         }
      }
      
      if(sparam == "btnCloseProfit"){
         closePositionInProfit();
      }
      if(sparam == "btnLockBuy"){
         if(lockBuy == ON){
            lockBuy = OFF;
         }else{
            lockBuy = ON;
         }
         generateButtons();
      }
      if(sparam == "btnLockSell"){
         if(lockSell == ON){
            lockSell = OFF;
         }else{
            lockSell = ON;
         }
         generateButtons();
      }
      
      if(sparam == "btnDoubleVol"){
         ACTIVE_VOLUME *= 2;   
      }
      
      if(sparam == "btnDivVol"){
         ACTIVE_VOLUME /= 2; 
         if(ACTIVE_VOLUME < VOLUME) {
            ACTIVE_VOLUME = VOLUME; 
         } 
      }
      
      if(sparam == "btnResetVol"){
         ACTIVE_VOLUME = VOLUME; 
      }
      
      if(sparam == "btnLockRobots"){
         LOCK_ROBOTS = !LOCK_ROBOTS; 
         generateButtons();
      }
      
      if(sparam == "btnUpTakeBuy"){
         moveAllTakePerPoint(AUTOMATIC_ROBOTS_TAKE, POSITION_TYPE_BUY);
      }
      
      if(sparam == "btnDownTakeBuy"){
         moveAllTakePerPoint(-AUTOMATIC_ROBOTS_TAKE, POSITION_TYPE_BUY);
      }
      
      if(sparam == "btnUpStopBuy"){
         moveAllStopPerPoint(AUTOMATIC_ROBOTS_STOP, POSITION_TYPE_BUY);
      }
      
      if(sparam == "btnDownStopBuy"){
         moveAllStopPerPoint(-AUTOMATIC_ROBOTS_STOP, POSITION_TYPE_BUY);
      }
      
      if(sparam == "btnUpTakeSell"){
         moveAllTakePerPoint(AUTOMATIC_ROBOTS_TAKE, POSITION_TYPE_SELL);
      }
      
      if(sparam == "btnDownTakeSell"){
         moveAllTakePerPoint(-AUTOMATIC_ROBOTS_TAKE, POSITION_TYPE_SELL);
      }
      
      if(sparam == "btnUpStopSell"){
         moveAllStopPerPoint(AUTOMATIC_ROBOTS_STOP, POSITION_TYPE_SELL);
      }
      
      if(sparam == "btnDownStopSell"){
         moveAllStopPerPoint(-AUTOMATIC_ROBOTS_STOP, POSITION_TYPE_SELL);
      }
   }
}
