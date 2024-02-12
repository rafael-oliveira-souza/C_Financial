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
input double ACTIVE_VOLUME = 0.1;
input double LOSS_PER_DAY = 30;
input double PROFIT_PER_DAY = 500;
input string SCHEDULE_START_PROTECTION = "00:00";
input string SCHEDULE_END_PROTECTION = "00:00";
input int NUMBER_MAX_ROBOTS = 25;
input int MAGIC_NUMBER = 200296;
int  WAIT_TICKS = 1500;
int  WAIT_CANDLES = 1;

MqlRates candles[];
datetime actualDay = 0;
bool negociationActive = false;
MqlTick tick;                // variável para armazenar ticks 


double CCI[], valuePrice = 0;
int handleICCI, countAverage = 0;
ORIENTATION orientMacro = MEDIUM;
double activeBalance= 0;
int numberMaxRobotsActive = 0, waitTicks = 0, waitCandles = 0; 
bool waitNewDay = false, dailyProfitReached = false;
int countRobots = 0, periodAval = 3;
int robots[];
datetime startedDatetimeRobot;
//+------------------------------------------------------------------+
//                                                                          | Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   handleICCI = iCCI(_Symbol,PERIOD,14,PRICE_TYPICAL);
   
   activeBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   numberMaxRobotsActive = NUMBER_MAX_ROBOTS;
   startedDatetimeRobot = TimeCurrent();
   
   ArrayResize(robots, numberMaxRobotsActive +2);
   for(int i = 0; i < numberMaxRobotsActive; i++)  {
      robots[i] = MAGIC_NUMBER + i; 
   }
   return(INIT_SUCCEEDED);
}
  
void OnTick() {
   if(isNewDay(startedDatetimeRobot)) {
      startedDatetimeRobot = TimeCurrent();
      printf("Novo dia iniciado!");
      waitNewDay = false;
   }

   if(!waitNewDay && verifyTimeToProtection()){
      int copiedPrice = CopyRates(_Symbol,PERIOD,0,3,candles);
      if(copiedPrice == 3){
            waitNewDay = verifyResultPerDay(startedDatetimeRobot);
         if(hasNewCandle()) {
            waitCandles--;
         }
         if(!hasPositionOpen(robots[countRobots]) && waitCandles <= 0){
           // showComments();
          //  long volume= iVolume(Symbol(),PERIOD,0);
            //if(volume) {
            //}
            if(CopyBuffer(handleICCI,0,0,periodAval,CCI) == periodAval && candles[periodAval-1].spread <= 15){
               MainCandles mainCandles = generateMainCandles();
               double actualCCI = CCI[periodAval-3];
               double lastCCI = CCI[periodAval-2];
               double secondLastCCI = CCI[periodAval-1];
               
               
               if(mainCandles.secondLastOrientation == UP &&  secondLastCCI >= 100) {
                  if(mainCandles.lastOrientation == UP &&  lastCCI >= 100) {
                     if(mainCandles.actualOrientation == DOWN &&  actualCCI < 100) {
                        if(mainCandles.actual.close < mainCandles.last.low) {
                           double max = mainCandles.last.high > mainCandles.secondLast.high ? mainCandles.last.high : mainCandles.secondLast.high;
                           max = max > mainCandles.actual.high ? max : mainCandles.actual.high;
                           
                           double take = calcPoints(mainCandles.secondLast.open, mainCandles.actual.close, true);
                           double stop = calcPoints(max, mainCandles.actual.close, true);
                           //if(stop <= take) {
                              toBuyOrToSell(DOWN, ACTIVE_VOLUME, stop, stop, robots[countRobots]);
                           //}
                        }
                     }
                  }               
               }
               else if(mainCandles.secondLastOrientation == DOWN &&  secondLastCCI <= -100) {
                  if(mainCandles.lastOrientation == DOWN && lastCCI <= -100) {
                     if(mainCandles.actualOrientation == UP &&  actualCCI > -100) {
                        if(mainCandles.actual.close > mainCandles.last.high) {
                           double max = mainCandles.last.high > mainCandles.secondLast.high ? mainCandles.last.high : mainCandles.secondLast.high;
                           max = max > mainCandles.actual.high ? max : mainCandles.actual.high;
                          
                           double take = calcPoints(mainCandles.secondLast.open, mainCandles.actual.close, true);
                           double stop = calcPoints(max, mainCandles.actual.close, true);
                          // if(stop <= take) {
                              toBuyOrToSell(UP, ACTIVE_VOLUME, stop, stop, robots[countRobots]);
                          // }
                        }
                     }
                  }               
               }
            }
         }
      }   
   }
}
//+------------------------------------------------------------------+
 void showComments(){
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   countRobots = PositionsTotal();
   Comment(
         " Total de robôs Disponiveis: ", (numberMaxRobotsActive - countRobots),
         " Total de robôs ativos: ", (countRobots), 
         " Saldo: ", DoubleToString(activeBalance + profit, 2),
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

bool realizeDeals(TYPE_NEGOCIATION typeDeals, double volume, double stopLoss, double takeProfit, int magicNumber){
   if(typeDeals != NONE){
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
      if(hasPositionOpen(magicNumber) == false) {
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
      closeBuyOrSell(robots[countRobots]);
   }
}

void closeBuyOrSell(int position){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      tradeLib.PositionClose(ticket);
      countRobots = PositionsTotal();
      if(verifyResultTrade()){
         Print("Negociação concluída.");
      }
   }
}

bool toBuyOrToSell(ORIENTATION orient, double volume, double stopLoss, double takeProfit, int magicNumber){
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


MainCandles generateMainCandles(){
   MainCandles mainCandles;
   int copiedPrice = CopyRates(_Symbol,_Period,0,3,candles);
   if(copiedPrice == 3){
      mainCandles.actual = candles[2];
      mainCandles.last = candles[1];
      mainCandles.secondLast = candles[0];
      mainCandles.actualOrientation = getCandleOrientantion(candles[2]);
      mainCandles.lastOrientation = getCandleOrientantion(candles[1]);
      mainCandles.secondLastOrientation = getCandleOrientantion(candles[0]);
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
            //moveAllStopPerPoint(50);
            return true;
         }
         if((-profit) > LOSS_PER_DAY){
            printf("Lucro diario excedido: %s.", DoubleToString(profit));
           // closeAll();
            return true;
         }
      }
   }
   
   return false;
}

void moveAllStopPerPoint(double points){
   for(int pos = countRobots; pos >= 0; pos--)  {
      int position = robots[countRobots];
      if(hasPositionOpen(position)){
         ulong ticket = PositionGetTicket(position);
         PositionSelectByTicket(ticket);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
            double newSl = currentPrice - (points * _Point);
            double tpPrice = PositionGetDouble(POSITION_TP);
         
            tradeLib.PositionModify(ticket, newSl,tpPrice);
            if(verifyResultTrade()){
               Print("Take movido");
            }
         }
         else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
            double newSl = currentPrice + (points * _Point);
            double tpPrice = PositionGetDouble(POSITION_TP);
         
            tradeLib.PositionModify(ticket, newSl,tpPrice);
            if(verifyResultTrade()){
               Print("Take movido");
            }
         }
      }
   }
}  

void instanciateBorder(BordersOperation& borders){
     borders.max = 0;
     borders.min = 0;
     borders.central = 0;
     borders.instantiated = false;
     borders.orientation = MEDIUM;
}