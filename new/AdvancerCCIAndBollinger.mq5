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
   NVL_1,
   NVL_2,
   NVL_3,
   NVL_4
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
input double PROPORTION_TAKE_STOP = 0.5;
input string SCHEDULE_START_PROTECTION = "00:00";
input string SCHEDULE_END_PROTECTION = "00:00";
input int NUMBER_MAX_ROBOTS = 10;
input int LOCK_ORDERS_BY_TYPE_IF_LOSS = 3;
input int LOCK_ORDERS_BY_SECONDS = 0;
input int ONLY_OPEN_NEW_ORDER_AFTER = 30;
input double PROTECT_ORDERS_IN_GAIN_BY_POINTS = 300;
input bool EXECUTE_CCI = true;
input bool EXECUTE_BOLLINGER_BANDS = true;
input bool CALIBRATE_ORDERS = true;
input bool MOVE_STOP_AND_TAKE = true;
input bool EXECUTE_EXPONENTIAL_ROBOTS = false;
input bool EXECUTE_EXPONENTIAL_VOLUME = true;
input int MAX_CCI_VALUE = 100;
input double INITIAL_BALANCE = 25;
input NIVEL NVL_BOLLINGER = NVL_4;
input NIVEL NVL_CCI = NVL_4;
 int MAX_FORCE_VALUE = 0;
 double MAX_BULLS_AND_BEARS_VALUE = 5;
 ulong MAGIC_NUMBER = 200296;
int WAIT_TICKS = 0;
int WAIT_CANDLES = 0;

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 


double Middle[], Upper[], Lower[];
double CCI[], IFORCE[], IBulls[], IBears[], valuePrice = 0;
int handleICCI, handleIForce, handleAverage9, handleAverage21, handleAverage80, handleAverage200, handleAverage400, handleAverage600, handleBears, handleBulls, handleBollinger;
ORIENTATION orientMacro = MEDIUM;
double ACTIVE_BALANCE= 0, LAST_BALANCE_ROBOTS = 0, LAST_BALANCE_GOALS = 0, ACTIVE_VOLUME = 0;
int numberMaxRobotsActive = 0, waitTicks = 0, waitCandlesBollinger = 0, waitCandles = 0, countAverage = 0; 
bool waitNewDay = false, dailyProfitReached = false;
int countRobots = 0, periodAval = 5;
ulong robots[];
datetime startedDatetimeRobot;
bool sellOrdersLocked = true,  buyOrdersLocked = true;
int ultimo = periodAval-1, penultimo = periodAval-2, antipenultimo = periodAval-3, primeiro = 0, segundo = 1, terceiro = 2;
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
   handleBollinger = iBands(_Symbol, PERIOD, 20, 0, 2, PRICE_CLOSE);
   //handleIForce = iForce(_Symbol,PERIOD,14, MODE_SMA, VOLUME_TICK);
   //handleBears = iBearsPower(_Symbol,PERIOD,14);
   //handleBulls = iBullsPower(_Symbol,PERIOD,14);
   ACTIVE_BALANCE = AccountInfoDouble(ACCOUNT_BALANCE);
   LAST_BALANCE_ROBOTS = AccountInfoDouble(ACCOUNT_BALANCE);
   LAST_BALANCE_GOALS = AccountInfoDouble(ACCOUNT_BALANCE);
   ACTIVE_VOLUME = VOLUME;
   numberMaxRobotsActive = NUMBER_MAX_ROBOTS;
   startedDatetimeRobot = TimeCurrent();
   initRobots(numberMaxRobotsActive);
   return(INIT_SUCCEEDED);
}
  
void OnTick() {
   countRobots = PositionsTotal();
   if(countRobots < numberMaxRobotsActive) {
      waitTicks--;
      if(isNewDay(startedDatetimeRobot)) {
         //INITIAL_BALANCE = AccountInfoDouble(ACCOUNT_BALANCE);
         startedDatetimeRobot = TimeCurrent();
         printf("Novo dia iniciado!");
         waitNewDay = false;
         waitCandles = 0;
         waitTicks = 0;
      }
      
      if(countRobots > 0 && PROTECT_ORDERS_IN_GAIN_BY_POINTS > 0) {
         protectOrderInGain(PROTECT_ORDERS_IN_GAIN_BY_POINTS);
      }
   
      if(!waitNewDay && verifyTimeToProtection()){
         int copiedPrice = CopyRates(_Symbol,PERIOD,0,periodAval,candles);
         if(copiedPrice == periodAval){
            waitNewDay = verifyResultPerDay(startedDatetimeRobot);
            if(hasNewCandle()) {
               waitCandles--;
               waitCandlesBollinger--;
              // showComments();
            }
            if(waitCandles <= 0 && waitTicks <= 0) {
               moveStopAndTake(PROTECT_ORDERS_IN_GAIN_BY_POINTS);
               executeExponentials();
               MainCandles mainCandles = generateMainCandles();
               if(sellOrdersLocked == true || buyOrdersLocked == true){
                  removeLockIfNotExistOrder();
               }
               if(EXECUTE_CCI){
                 executeCCI(mainCandles);
               }
               if(EXECUTE_BOLLINGER_BANDS){
                  executeBollingerBands(mainCandles);
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
         if(NVL_CCI == NVL_1){
            calibrateOrdersAndSellCCI(mainCandles);
            return;
         }
         if((mainCandles.lastOrientation == UP &&  lastIdx >= MAX_CCI_VALUE)) {
            if(NVL_CCI == NVL_2){
               calibrateOrdersAndSellCCI(mainCandles);
               return;
            }
            if((mainCandles.actualOrientation != UP &&  actualIdx <= MAX_CCI_VALUE)) {
               if(NVL_CCI == NVL_3){
                  calibrateOrdersAndSellCCI(mainCandles);
                  return;
               }
               if((mainCandles.actual.close <= mainCandles.last.low )) {
                  calibrateOrdersAndSellCCI(mainCandles);
                  return;
               }
            }
         }               
      }
      else if((mainCandles.secondLastOrientation == DOWN &&  secondLastIdx <= -MAX_CCI_VALUE)) {
         if(NVL_CCI == NVL_1){
            calibrateOrdersAndBuyCCI(mainCandles);
            return;
         }
         if((mainCandles.lastOrientation == DOWN && lastIdx <= -MAX_CCI_VALUE)) {
            if(NVL_CCI == NVL_2){
               calibrateOrdersAndBuyCCI(mainCandles);
               return;
            }
            if((mainCandles.actualOrientation != DOWN &&  actualIdx >= -MAX_CCI_VALUE)) {
               if(NVL_CCI == NVL_3){
                  calibrateOrdersAndBuyCCI(mainCandles);
                  return;
               }
               
               if((mainCandles.actual.close >= mainCandles.last.high)) {
                  calibrateOrdersAndBuyCCI(mainCandles);
                  return;
               }
            }
         }               
      }   
   }
}

void calibrateOrdersAndSellCCI(MainCandles& mainCandles){ 
   double max = mainCandles.last.high > mainCandles.secondLast.high ? mainCandles.last.high : mainCandles.secondLast.high;
   max = max > mainCandles.actual.high ? max : mainCandles.actual.high;
   double stop = calcPoints(max, mainCandles.actual.close, true);
   double take =  stop * PROPORTION_TAKE_STOP;
 
   lockOrderInLoss();
   if(!sellOrdersLocked) {
      calibrateOrdersAndBuyOrSell(DOWN, stop, take);
   }
}

void calibrateOrdersAndBuyCCI(MainCandles& mainCandles){ 
   double max = mainCandles.last.high > mainCandles.secondLast.high ? mainCandles.last.high : mainCandles.secondLast.high;
   max = max > mainCandles.actual.high ? max : mainCandles.actual.high;
   double stop = calcPoints(max, mainCandles.actual.close, true);
   double take = stop * PROPORTION_TAKE_STOP;
   
   lockOrderInLoss();
   if(!buyOrdersLocked) {
      calibrateOrdersAndBuyOrSell(UP, stop, take);
   }
}

void executeBollingerBands(MainCandles& mainCandles){ 
   if(waitCandlesBollinger <= 0) {
      if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval
         && CopyBuffer(handleBollinger, 0, 0, periodAval, Middle) == periodAval
         && CopyBuffer(handleBollinger, 1, 0, periodAval, Upper) == periodAval
         && CopyBuffer(handleBollinger, 2, 0, periodAval, Lower) == periodAval) {
         if(getCandleOrientantion(candles[primeiro]) == UP  && candles[primeiro].close >= Upper[primeiro] ) {
            if(NVL_BOLLINGER == NVL_1){
               calibrateOrdersAndSellBollinger(mainCandles);
               return;
            }
            if(getCandleOrientantion(candles[segundo]) == UP  && candles[segundo].close >= Upper[segundo] ) {
               if(NVL_BOLLINGER == NVL_2){
                  calibrateOrdersAndSellBollinger(mainCandles);
                  return;
               }
               if(CCI[primeiro] >= MAX_CCI_VALUE && CCI[ultimo] <= MAX_CCI_VALUE) {
                  if(NVL_BOLLINGER == NVL_3){
                     calibrateOrdersAndSellBollinger(mainCandles);
                     return;
                  }
                  if(mainCandles.actualOrientation == DOWN && mainCandles.actual.close <= Upper[ultimo]) {
                     calibrateOrdersAndSellBollinger(mainCandles);
                     return;
                  } 
               }
            }              
         }
         else if(getCandleOrientantion(candles[primeiro]) == DOWN  && candles[primeiro].close <= Lower[primeiro] ) {
            if(NVL_BOLLINGER == NVL_1){
               calibrateOrdersAndBuyBollinger(mainCandles);
               return;
            }
            if(getCandleOrientantion(candles[segundo]) == DOWN  && candles[segundo].close <= Lower[segundo]) {
               if(NVL_BOLLINGER == NVL_2){
                  calibrateOrdersAndBuyBollinger(mainCandles);
                  return;
               }
               if( CCI[primeiro] <= -MAX_CCI_VALUE  && CCI[ultimo] >= -MAX_CCI_VALUE) {
                  if(NVL_BOLLINGER == NVL_3){
                     calibrateOrdersAndBuyBollinger(mainCandles);
                     return;
                  }
                  if(mainCandles.actualOrientation == UP && mainCandles.actual.close >= Lower[ultimo]) {
                     calibrateOrdersAndBuyBollinger(mainCandles);
                     return;
                  }  
               }             
            }
         }  
      }
   }
}

void calibrateOrdersAndSellBollinger(MainCandles& mainCandles){ 
   double percent = 0.7;
   double stop = calcPoints(Upper[ultimo], Middle[ultimo], true)* percent;
   double take = stop * PROPORTION_TAKE_STOP;
 
   lockOrderInLoss();
   if(!sellOrdersLocked) {
      calibrateOrdersAndBuyOrSell(DOWN, stop, take);
      waitCandlesBollinger = 0;
   }
}

void calibrateOrdersAndBuyBollinger(MainCandles& mainCandles){ 
   double percent = 0.7;
   double stop = calcPoints(Lower[ultimo], Middle[ultimo], true)* percent;
   double take = stop * PROPORTION_TAKE_STOP;
 
 
   lockOrderInLoss();
   if(!buyOrdersLocked) {
      calibrateOrdersAndBuyOrSell(UP, stop, take);
      waitCandlesBollinger = 0;
   }
}

void strategyV(){
   int periodAvalV = 5;
   MqlRates candlesV[];
   double CCIV[];
   
   if(CopyRates(_Symbol,PERIOD,0,periodAvalV,candlesV) == periodAvalV) {
      if(CopyBuffer(handleICCI,0,0,periodAvalV,CCIV) == periodAvalV) {
        Averages averages = generateMainAverages();
        if(inInterval(averages.a9, candlesV[periodAvalV-1].close)
            || inInterval(averages.a21, candlesV[periodAvalV-1].close)
            || inInterval(averages.a80, candlesV[periodAvalV-1].close)
            || inInterval(averages.a200, candlesV[periodAvalV-1].close)
            || inInterval(averages.a400, candlesV[periodAvalV-1].close)
            || inInterval(averages.a600, candlesV[periodAvalV-1].close)) {
               if(CCIV[0] <= -MAX_CCI_VALUE 
                  && CCIV[periodAvalV-1] <= -MAX_CCI_VALUE  
                  && CCIV[2] >= -MAX_CCI_VALUE) {
                bool sequence = validateSequence(candlesV, 0, periodAvalV-2, true);
                bool sequence2 = validateSequence(candlesV, periodAvalV-2, periodAvalV-1, false);
                if(sequence && sequence2 && candlesV[periodAvalV-1].close < candlesV[periodAvalV-2].open ) {
                   double take = calcPoints(candlesV[0].open, candlesV[periodAvalV-1].close);
                   double stop = calcPoints(candlesV[periodAvalV-2].high, candlesV[periodAvalV-1].close);
                   lockOrderInLoss();
                   if(!sellOrdersLocked) {
                      calibrateOrdersAndBuyOrSell(DOWN, stop, take);
                   }
                }
              }
              else if(CCIV[0] >= -MAX_CCI_VALUE 
                  && CCIV[periodAvalV-1] >= -MAX_CCI_VALUE  
                  && CCIV[2] <= -MAX_CCI_VALUE) {
                bool sequence = validateSequence(candlesV, 0, periodAvalV-2, false);
                bool sequence2 = validateSequence(candlesV, periodAvalV-2, periodAvalV-1, true);
                if(sequence && sequence2 && candlesV[periodAvalV-1].close > candlesV[periodAvalV-2].open ) {
                   double take = calcPoints(candlesV[0].open, candlesV[periodAvalV-1].close);
                   double stop = calcPoints(candlesV[periodAvalV-2].low, candlesV[periodAvalV-1].close);
                   lockOrderInLoss();
                   if(!buyOrdersLocked) {
                      calibrateOrdersAndBuyOrSell(UP, stop, take);
                   }
                }
              }   
         }
      }
   }
}

bool validateSequence(MqlRates& candlesV[], int start, int end, bool isUp) {
   double media1 = 0, media2 = 0;
   bool isSequence = true;
   for(int i = start; i < end; i++) {
      media1 = (candlesV[i].open + candlesV[i].close) / 2;
      media2 = (candlesV[i+1].open + candlesV[i+1].close) / 2;
      if(isUp) {
         if(candlesV[i].open  > candlesV[i+1].close){
           isSequence = false;
         }
      }else {
         if(candlesV[i].open  < candlesV[i+1].close){
           isSequence = false;
         }
      }
   }
   
   return isSequence;
}

void lockOrderInLoss(){
   int sellOrdersInLoss = 0, buyOrdersInLoss = 0;
   if(LOCK_ORDERS_BY_TYPE_IF_LOSS > 0){
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
         
            if(profit < 0 && (LOCK_ORDERS_BY_SECONDS <=0 || verifyIfSecondsIsBetterThanTimeFromPosition(now, position, LOCK_ORDERS_BY_SECONDS))){
               Print("Is Locked to " + IntegerToString(PositionGetInteger(POSITION_TYPE)));
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                 buyOrdersInLoss++;
               }
               else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                 sellOrdersInLoss++;
               }
            }
         }
      }
      
      if(buyOrdersInLoss >= LOCK_ORDERS_BY_TYPE_IF_LOSS) {
         buyOrdersLocked = true;
      }
      if(sellOrdersInLoss >= LOCK_ORDERS_BY_TYPE_IF_LOSS) {
        sellOrdersLocked = true;
      }
   }
   
}

void removeLockIfNotExistOrder(){
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

void calibrateOrdersAndBuyOrSell(ORIENTATION orient, double stopLossPoints, double take){
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
      toBuyOrToSell(orient, volume, stopLossPoints, take, robots[countRobots]);
   }
}

double calculateBullsAndBearsPower(double bullsPower, double bearsPower, bool absValue = true){
   return absValue ? (MathAbs(bullsPower) + MathAbs(bearsPower)) : (bullsPower + bearsPower);
}

//+------------------------------------------------------------------+
void showComments(){
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   Comment(
         " Total de robôs Disponiveis: ", (numberMaxRobotsActive - countRobots),
         " Total de robôs ativos: ", (countRobots), 
         " Saldo: ", DoubleToString(ACTIVE_BALANCE + profit, 2),
         " Lucro Atual: ", DoubleToString(profit, 2),
         " Volume: ", ACTIVE_VOLUME);
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

bool realizeDeals(TYPE_NEGOCIATION typeDeals, double volume, double stopLoss, double takeProfit, ulong magicNumber){
   if(typeDeals != NONE){
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
      if(countRobots <= NUMBER_MAX_ROBOTS && hasPositionOpenWithMagicNumber(countRobots, magicNumber) == false) {
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

bool toBuyOrToSell(ORIENTATION orient, double volume, double stopLoss, double takeProfit, ulong magicNumber){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   return realizeDeals(typeDeal, volume, stopLoss, takeProfit, magicNumber);
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
            
            if( profit > 0 && (pointsGain >= points) && newSl <= entryPrice && newSl <= entryPrice){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                   newSl = entryPrice + (points * 0.2 * _Point);
               }
               else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                   newSl = entryPrice - (points * 0.2 * _Point);
               }
               
               tradeLib.PositionModify(ticket, newSl, newTake);
               if(verifyResultTrade()){
                  Print("Ordem Protegida");
               }
            }
         }
      }
   }
}  

void moveStopAndTake(double points){
   if(MOVE_STOP_AND_TAKE) {
      for(int position = PositionsTotal(); position >= 0; position--)  {
         ulong magicNumber = robots[position];
         if(hasPositionOpenWithMagicNumber(position, magicNumber)){
            ulong ticket = PositionGetTicket(position);
            PositionSelectByTicket(ticket);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double newTake = PositionGetDouble(POSITION_TP);
            double pointsGain = calcPoints(entryPrice, currentPrice, true);
            double pointsToTake = calcPoints(newTake, currentPrice, true);
            
           if( profit > 0 && pointsGain >= pointsToTake * 0.5){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                  // newTake = newTake + (points * _Point);
                   moveStopPerPoint(position, points);
               }
               else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                   //newTake = newTake - (points * _Point);
                   moveStopPerPoint(position, points);
               }
               /*
               double newSl = PositionGetDouble(POSITION_SL);
               tradeLib.PositionModify(ticket, newSl, newTake);
               if(verifyResultTrade()){
                  Print("Take Avancado");
               }  */
            }
         }
      }
   }
}  

void moveAllStopPerPoint(double points){
   for(int position = PositionsTotal(); position >= 0; position--)  {
      ulong magicNumber = robots[position];
      moveStopPerPoint(position, points);
   }
}  

void moveStopPerPoint(int position, double points, double tpPrice = 0){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double profit = PositionGetDouble(POSITION_PROFIT);
      double tpPrice = PositionGetDouble(POSITION_TP);
      double slPrice = PositionGetDouble(POSITION_SL);
      double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double pointsGain = calcPoints(entryPrice, currentPrice, true);
      
      if(profit > 0 && pointsGain >= points) {
         if(tpPrice > 0) {
            tpPrice = PositionGetDouble(POSITION_TP);
         }
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
            double newSl = slPrice + (points * _Point);
            if( newSl > slPrice || slPrice <= entryPrice){
               tradeLib.PositionModify(ticket, newSl,tpPrice);
               if(verifyResultTrade()){
                  Print("Stop movido");
               }
            }
         }
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
            double newSl = slPrice - (points * _Point);
            if( newSl < slPrice || slPrice <= entryPrice){
               tradeLib.PositionModify(ticket, newSl,tpPrice);
               if(verifyResultTrade()){
                  Print("Stop movido");
               }
            }
         }
      }
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
   if(EXECUTE_EXPONENTIAL_VOLUME) {
      double minimunVolume = 0.01;
      double goal = INITIAL_BALANCE * 5;
      double goalBalanceUp = LAST_BALANCE_GOALS + goal;
      double goalBalanceDown = LAST_BALANCE_GOALS - goal;
      
      if(goalBalanceUp > 0  && balance > goalBalanceUp) {
        ACTIVE_VOLUME =  NormalizeDouble(ACTIVE_VOLUME + minimunVolume, 2);
        LAST_BALANCE_GOALS = goalBalanceUp;
      }else if(goalBalanceDown > 0 && ACTIVE_VOLUME > minimunVolume && balance <= goalBalanceDown){
        ACTIVE_VOLUME =  NormalizeDouble(ACTIVE_VOLUME - minimunVolume, 2);
        LAST_BALANCE_GOALS = goalBalanceDown;
      }
   }
   
   if(EXECUTE_EXPONENTIAL_ROBOTS) {
      double goal = INITIAL_BALANCE * 0.5;
      double goalBalanceUp = LAST_BALANCE_ROBOTS + goal;
      double goalBalanceDown = LAST_BALANCE_ROBOTS - goal;
      
      if(goalBalanceUp > 0 && balance > goalBalanceUp) {
        numberMaxRobotsActive++;
        initRobots(numberMaxRobotsActive);
        LAST_BALANCE_ROBOTS = goalBalanceUp;
      }else if(goalBalanceDown > 0 &&  numberMaxRobotsActive > 1 && balance <= goalBalanceDown){
        numberMaxRobotsActive--;
        initRobots(numberMaxRobotsActive);
        LAST_BALANCE_ROBOTS = goalBalanceDown;
      }
   }
   
}

void initRobots(int numRobots) {
   ArrayResize(robots, numRobots);
   for(int i = 0; i < numRobots; i++)  {
      robots[i] = MAGIC_NUMBER + i; 
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