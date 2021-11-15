//+------------------------------------------------------------------+
//|                                                     platform.mq5 |
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

enum TYPE_ORDER{
   NO_ORDER,
   LIMIT,
   STOP,
   STOP_LIMIT,
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

enum POSITION_GRAPHIC{
   BOTTOM,
   TOP,
   CENTER
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

ENUM_TIMEFRAMES TIME_FRAME = PERIOD_CURRENT;
input double PERCENT_MARGIN_OPERATION = 10;
input POWER  ACTIVE_MOVE_TAKE = ON;
input POWER  ACTIVE_MOVE_STOP = ON;
input double PERCENT_MOVE = 40;
input double PONTUATION_MOVE_STOP = 400;
ulong MAGIC_NUMBER = 3232131231231231;
input double TAKE_PROFIT = 400;
input double STOP_LOSS = 400;
input double VOLUME = 0.01;
input int NUMBER_ROBOTS = 5;
input double DAILY_GOAL = 2;
input int COUNT_TICKS = 20;

POWER IGNORE_MAGIC =  ON;
POWER  LOCK_IN_LOSS = OFF;
POWER USE_MAGIC_NUMBER = ON;
double ACTIVE_VOLUME = VOLUME;
double BALANCE_ACTIVE = 0, INITIAL_BALANCE = 0, INITIAL_INVESTIMENT_ACTIVE = 0, INITIAL_INVESTIMENT = 0;

MqlRates candles[];
datetime actualDay = 0;
MqlTick tick;                // variável para armazenar ticks 

ORIENTATION orientMacro = MEDIUM;
int periodAval = 4, countRobots = 0, countTicks = 0   , countCandles = 0;
int WAIT_NEW_CANDLE = 0;
double saldoAtual = 0;
datetime  diaAtual = TimeCurrent();

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){
//---
   // Fechar negociacões
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "btnCloseBuy"){
         closeAllPositionsByType(POSITION_TYPE_BUY, 0);
      }
      if(sparam == "btnCloseSell"){
         closeAllPositionsByType(POSITION_TYPE_SELL, 0);
      }
      
      if(sparam == "btnCloseAll"){
         closeAll();
         closeOrdersByDuration(0);
      }
      if(sparam == "btnMoveStop"){
         protectPositions(15);
      }
      if(sparam == "btnBuy"){
         ulong magic = MAGIC_NUMBER + 6000;
         for(int i = 0; i < NUMBER_ROBOTS; i++){
            magic = magic + i;
            realizeDeals(BUY, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT, MAGIC_NUMBER);
         }
      }
      if(sparam == "btnSell"){
         ulong magic = MAGIC_NUMBER + 6000;
         for(int i = 0; i < NUMBER_ROBOTS; i++){
            magic = magic + i;
            realizeDeals(SELL, ACTIVE_VOLUME, STOP_LOSS, TAKE_PROFIT, MAGIC_NUMBER);
         }
      }
      
      if(sparam == "btnCloseProfit"){
         closePositionInProfit();
      }
      
      if(sparam == "btnCloseLoss"){
         closePositionInLoss();
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
    
   }
}

int OnInit(){
      generateButtons();
      
      BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
      saldoAtual = BALANCE_ACTIVE;
      INITIAL_BALANCE = BALANCE_ACTIVE;
      INITIAL_INVESTIMENT_ACTIVE = BALANCE_ACTIVE;
      INITIAL_INVESTIMENT = BALANCE_ACTIVE;
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
   int copiedPrice = CopyRates(_Symbol,TIME_FRAME,0,periodAval,candles);
   if(copiedPrice == periodAval){         Print("Robôs em operação");
      double spread = candles[periodAval-1].spread;
      if(hasNewCandle()){
         WAIT_NEW_CANDLE--;
         countCandles--;
      }else{
         double investiment = MathAbs(saldoAtual-INITIAL_INVESTIMENT);
         if(DAILY_GOAL <= 0 || (investiment <= DAILY_GOAL)){
            if(WAIT_NEW_CANDLE <= 0){
               executeIdealOrder();
               if(countTicks <= 0){
                  moveAllPositions(spread);
               }
               countTicks--;
            }
         }else{
            Alert("Você bateu a meta diaria");
            int diffDay = daysDiff(diaAtual);
            if(diffDay >= 1){
               diaAtual = TimeCurrent();
               INITIAL_INVESTIMENT = INITIAL_INVESTIMENT + (saldoAtual-INITIAL_INVESTIMENT);
            }
         }
      }
   }
   showComments();
}

void showComments(){
    BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   saldoAtual = BALANCE_ACTIVE + profit;
   Comment(" Saldo: ", DoubleToString(saldoAtual, 2),
         " Lucro Atual: ", DoubleToString(profit, 2),
         " Volume: ", ACTIVE_VOLUME);
}



void moveAllPositions(double spread){
   int pos = PositionsTotal() - 1;
   double  average[];
   
   for(int i = pos; i >= 0; i--)  {
      if(hasPositionOpen(i)){
         if(ACTIVE_MOVE_STOP == ON){
            activeStopMovelPerPoints(PONTUATION_MOVE_STOP+spread, i);
         }
         if(ACTIVE_MOVE_TAKE == ON){
            moveTakeProfit(i);
         }
      }
   }
}


void executeIdealOrder(){
   BALANCE_ACTIVE = AccountInfoDouble(ACCOUNT_BALANCE);
   int pos = OrdersTotal();
   
   double percentMarginOp = PERCENT_MARGIN_OPERATION / pos;
   for(int position = 0; position < pos; position++)  {
      if(hasOrderOpen(position)){
         ulong ticket = OrderGetTicket(position);
         ulong magicNumber = OrderGetInteger(ORDER_MAGIC);
         ulong orderType = OrderGetInteger(ORDER_TYPE);
         double tpPrice = OrderGetDouble(ORDER_TP);
         double slPrice = OrderGetDouble(ORDER_SL);
         double volume = OrderGetDouble(ORDER_VOLUME_INITIAL);
         double currentPrice = OrderGetDouble(ORDER_PRICE_CURRENT );
         double entryPrice = OrderGetDouble(ORDER_PRICE_OPEN);
         double pointsTP = calcPoints(entryPrice, tpPrice);
         double pointsSL = calcPoints(entryPrice, slPrice);
         double marginOperation = BALANCE_ACTIVE * (percentMarginOp / 100);
         double newVolume = NormalizeDouble((marginOperation / pointsSL), _Digits);
        // BALANCE_ACTIVE = (BALANCE_ACTIVE - (pointsSL * newVolume));
         ORIENTATION orient = MEDIUM;
         
         Print(percentMarginOp);
         if(newVolume !=  volume && slPrice != 0){
            tradeLib.OrderDelete(ticket);
            if(verifyResultTrade()){
               if(orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_SELL_STOP){
                  orient = (orderType == ORDER_TYPE_BUY_STOP ? UP : DOWN);
                  toBuyOrToSellOrders(STOP, orient, newVolume, entryPrice, (pointsSL), (pointsTP), MAGIC_NUMBER);
               }
               if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_SELL_LIMIT){
                  orient = (orderType == ORDER_TYPE_BUY_LIMIT ? UP : DOWN);
                  toBuyOrToSellOrders(LIMIT, orient, newVolume, entryPrice, (pointsSL), (pointsTP), MAGIC_NUMBER);
               }
            }
         }
      }
   }
}

void  moveTakeProfit( int position = 0){
   double newTpPrice = 0, newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      ulong ticket = PositionGetTicket(position);
      
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
            double tpPrice = PositionGetDouble(POSITION_TP);
            double slPrice = PositionGetDouble(POSITION_SL);
            double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
            double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double profit = PositionGetDouble(POSITION_PROFIT);
            double pointsProfit =  MathAbs(profit / ACTIVE_VOLUME);
            double pointsTake = calcPoints(entryPrice, tpPrice);
            double pointsSL = calcPoints(entryPrice, slPrice);
            newTpPrice = tpPrice;
            
            if(profit > 0){
              newSlPrice = slPrice;
              if(pointsProfit >= pointsTake * PERCENT_MOVE / 100 ){
                  double mov =  NormalizeDouble((pointsTake * PERCENT_MOVE / 100 * _Point), _Digits);
                  if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
                     newTpPrice = (tpPrice + mov);
                     newSlPrice = (tpPrice + mov);
                   //  slPrice = slPrice > entryPrice ? slPrice : entryPrice;
                  }
                  else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
                     newTpPrice = (tpPrice - mov);
                     newSlPrice = (tpPrice - mov);
                    // slPrice = slPrice < entryPrice ? slPrice : entryPrice;
                  }
                  
                  tradeLib.PositionModify(ticket, slPrice, newTpPrice);
                  if(verifyResultTrade()){
                     Print("Take movido");
                  }
              }
           }
       }
   }
}



void  moveStopToZeroPlusPoint(int position = 0, double points = 0){
   double newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double tpPrice = PositionGetDouble(POSITION_TP);
         double slPrice = PositionGetDouble(POSITION_SL);
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
            if(slPrice < entryPrice){
               if(currentPrice > entryPrice+(points*_Point)){
                  tradeLib.PositionModify(ticket, entryPrice+(points*_Point), tpPrice);
               }
               else{
                  tradeLib.PositionModify(ticket, entryPrice, tpPrice);
               }
            }
            if(verifyResultTrade()){
               Print("Stop movido pro zero");
            }
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
            if(slPrice > entryPrice){
               if(currentPrice < entryPrice-(points*_Point)){
                  tradeLib.PositionModify(ticket, entryPrice-(points*_Point), tpPrice);
               }
               else{
                  tradeLib.PositionModify(ticket, entryPrice, tpPrice);
               }
            }
            if(verifyResultTrade()){
               Print("Stop movido pro zero");
            }
         }
      }
   }
}

void  activeStopMovelPerPoints(double points, int position = 0){
   double newSlPrice = 0;
   if(hasPositionOpen(position)){ 
      Print("Mover Stop");
      PositionSelectByTicket(PositionGetTicket(position));
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double tpPrice = PositionGetDouble(POSITION_TP);
         double slPrice = PositionGetDouble(POSITION_SL);
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double entryPoints = 0, pointsInversion =  MathAbs(profit / ACTIVE_VOLUME);
         double pointsTake = calcPoints(entryPrice, tpPrice);
         bool modify = false, inversion = false;
         ORIENTATION orient = MEDIUM;
         newSlPrice = slPrice;
         
         double pointsMove = (points * _Point);
         double percentMove = (points * PERCENT_MOVE / 100 * _Point);
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ){
            //tpPrice = NormalizeDouble((tpPrice + (points * _Point)), _Digits);
            if(currentPrice >= (slPrice + pointsMove) && slPrice >= entryPrice){
               newSlPrice = NormalizeDouble((slPrice + percentMove), _Digits);
               modify = true;
            }
            else if(currentPrice >= (entryPrice + pointsMove) && slPrice <= entryPrice){
               newSlPrice = NormalizeDouble((entryPrice ), _Digits);
               modify = true;
            }
           // else if(currentPrice > entryPrice + (10 * _Point)){
             //   newSlPrice = NormalizeDouble((entryPrice + (10 * _Point) ), _Digits);
               // modify = true;
            //}
         }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL ){
          //  tpPrice = NormalizeDouble((tpPrice - (points * _Point)), _Digits);
            if(currentPrice <= (slPrice - pointsMove) && slPrice <= entryPrice ){
               newSlPrice = NormalizeDouble((slPrice - percentMove), _Digits);
               modify = true;
            }else if(currentPrice <= (entryPrice - pointsMove) && slPrice >= entryPrice ){
               newSlPrice = NormalizeDouble((entryPrice), _Digits);
               modify = true;
            }
           // else if(currentPrice < entryPrice - (10 * _Point)){
             //   newSlPrice = NormalizeDouble((entryPrice - (10 * _Point)), _Digits);
              //  modify = true;
            //}
         }
            
         if(modify == true ){
            tradeLib.PositionModify(PositionGetTicket(position), newSlPrice, tpPrice);
            if(verifyResultTrade()){
               Print("Stop movido");
            }
         }
      }
   }
}


void  closePositionByDuration(long duration){
   int pos = OrdersTotal() - 1;
   for(int position = pos; position >= 0; position--)  {
      ulong ticket = PositionGetTicket(position);
      if(hasPositionOpen(position)){
         MqlDateTime structActual, structTime;
         long time = PositionGetInteger(POSITION_TIME);
         TimeToStruct((time+ duration), structActual);
         TimeToStruct((time), structTime);
         datetime durationTotal = StructToTime(structActual);
         datetime timeInit = StructToTime(structTime);
         datetime now = TimeCurrent();
         
         if(now > durationTotal){
            closeBuyOrSell(position);
            if(verifyResultTrade()){
               Print("Close Position");
            }
         }
      }
   }
}



void  closeOrdersByDuration(long duration){
   int pos = OrdersTotal() - 1;
   for(int position = pos; position >= 0; position--)  {
      if(hasOrderOpen(position)){
         ulong ticket = OrderGetTicket(position);
         ulong magicNumber = OrderGetInteger(ORDER_MAGIC);
         if(verifyMagicNumber(position, magicNumber, true)){
            MqlDateTime structActual, structTime;
            long time = OrderGetInteger(ORDER_TIME_SETUP);
            TimeToStruct((time+ duration), structActual);
            TimeToStruct((time), structTime);
            datetime durationTotal = StructToTime(structActual);
            datetime timeInit = StructToTime(structTime);
            datetime now = TimeCurrent();
            
            if(now > durationTotal){
               tradeLib.OrderDelete(ticket);
               if(verifyResultTrade()){
                  Print("Close Order");
               }
            }
         }
      }
   }
}

void moveStopPerPoint(ENUM_POSITION_TYPE type, double points){
   int pos = PositionsTotal() - 1;
   for(int position = pos; position >= 0; position--)  {
      moveStopOrTake(type, true, position, points);
   }
}  

void moveTakePerPoint(ENUM_POSITION_TYPE type, double points){
   int pos = PositionsTotal() - 1;
   for(int position = pos; position >= 0; position--)  {
      moveStopOrTake(type, false, position, points);
   }
}  

void moveStopOrTake(ENUM_POSITION_TYPE type, bool stop, int position, double points){
   if(hasPositionOpen(position)){
      ulong ticket = PositionGetTicket(position);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(position, magicNumber)){
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double slPrice = PositionGetDouble(POSITION_SL);
         double tpPrice = PositionGetDouble(POSITION_TP);
         double profit = PositionGetDouble(POSITION_PROFIT);
         double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         double pointsSl   = calcPoints(currentPrice, slPrice);
         double newTP = NormalizeDouble(tpPrice + (points * _Point), _Digits);
         double newSl = NormalizeDouble(slPrice + (points * _Point), _Digits);
         
            
     
      
         if(PositionGetInteger(POSITION_TYPE) == type){
            double valN = NormalizeDouble(entryPrice - (points * _Point), _Digits);
            double valP =NormalizeDouble( entryPrice + (points * _Point), _Digits);
            if(stop){
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                  if(newSl < valN){
                     tradeLib.PositionModify(ticket, newSl,tpPrice);   
                  }
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  if(newSl > valP){
                     tradeLib.PositionModify(ticket, newSl,tpPrice);   
                  }
               }      
            }else{
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                  if(newTP < valN){
                     tradeLib.PositionModify(ticket, slPrice,newTP);
                  }
               }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                  if(newTP > valP){
                   tradeLib.PositionModify(ticket, slPrice,newTP);
                  }
               }
            }
            if(verifyResultTrade()){
               Print("Take movido");
            }
         }
       }
    }
   
}

BordersOperation normalizeTakeProfitAndStopLoss(double stopLoss, double takeProfit){
   BordersOperation borders;
   // modificação para o indice dolar DOLAR_INDEX
   if(stopLoss != 0 || takeProfit != 0){
      if( _Symbol == "USDHKD" ){
         borders.min = (stopLoss / 1000);
         borders.max = (takeProfit / 1000);  
      }if(_Digits == 3  ){
         borders.min = (stopLoss * 1000);
         borders.max = (takeProfit * 1000);  
      }else{
         borders.min = NormalizeDouble((stopLoss * _Point), _Digits);
         borders.max = NormalizeDouble((takeProfit * _Point), _Digits); 
      }
   }
   
   return borders;
}


void toBuyOrder(TYPE_ORDER orderType, double volume, double limitPrice, double stopLoss, double takeProfit, datetime duration){
   double stopLossNormalized = NormalizeDouble((limitPrice - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((limitPrice + takeProfit), _Digits);
   
   if(orderType == LIMIT){
      tradeLib.BuyLimit(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration); 
   }  
   else if(orderType == STOP){
      tradeLib.BuyStop(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration); 
   } 
   
   if(verifyResultTrade()){
      Print("Compra Limitada realizada.");
   }
}

void toSellOrder(TYPE_ORDER orderType, double volume, double limitPrice, double stopLoss, double takeProfit, datetime duration){
   double stopLossNormalized = NormalizeDouble((limitPrice + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((limitPrice - takeProfit), _Digits);
   
   if(orderType == LIMIT){
      tradeLib.SellLimit(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration); 
   }  
   else if(orderType == STOP){
      tradeLib.SellStop(volume, limitPrice, _Symbol, stopLossNormalized, takeProfitNormalized,ORDER_TIME_GTC, duration); 
   } 
   
   if(verifyResultTrade()){
      Print("Venda Limitada realizada.");
   }
}

void toBuy(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.ask - stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.ask + takeProfit), _Digits);
   tradeLib.Buy(volume, _Symbol, NormalizeDouble(tick.ask,_Digits), stopLossNormalized, takeProfitNormalized); 
  
   if(verifyResultTrade()){
      Print("Compra realizada.");
   }
}

void toSell(double volume, double stopLoss, double takeProfit){
   SymbolInfoTick(_Symbol, tick);
   double stopLossNormalized = NormalizeDouble((tick.bid + stopLoss), _Digits);
   double takeProfitNormalized = NormalizeDouble((tick.bid - takeProfit), _Digits);
   tradeLib.Sell(volume, _Symbol, NormalizeDouble(tick.bid,_Digits), stopLossNormalized, takeProfitNormalized);   
   
   if(verifyResultTrade()){
      Print("Venda realizada.");
   }
}

bool realizeDealsOrders(TYPE_ORDER orderType, TYPE_NEGOCIATION typeDeals, double volume, double limitPrice, double stopLoss, double takeProfit, ulong magicNumber, datetime duration){
   if(typeDeals != NONE){
   
      BordersOperation borders = normalizeTakeProfitAndStopLoss(stopLoss, takeProfit); 
    //  if(hasPositionOpen() == false) {
         if(typeDeals == BUY){ 
            toBuyOrder(orderType, volume,limitPrice, borders.min, borders.max, duration);
         }
         else if(typeDeals == SELL){
            toSellOrder(orderType, volume,limitPrice, borders.min, borders.max, duration);
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
            countRobots = (countRobots-1 < 0 ? 0 : countRobots--);
         }
      }
   }
}

bool verifyMagicNumber(int position = 0, ulong magicNumberRobot = 0, bool order = false){
   if(USE_MAGIC_NUMBER == OFF || IGNORE_MAGIC == ON){
      return true;
   }
   
   if(!order){
      if(hasPositionOpen(position)){
         if(magicNumberRobot == MAGIC_NUMBER){
            return true;
         }
      }
   }else{
      if(hasOrderOpen(position)){ 
         if(magicNumberRobot == MAGIC_NUMBER){
            return true;
         }
      }
   }
   
   return false;
   
}

bool toBuyOrToSellOrders(TYPE_ORDER orderType, ORIENTATION orient, double volume, double limitPrice, double stopLoss, double takeProfit, ulong magicNumber, datetime duration = 0){
   TYPE_NEGOCIATION typeDeal = NONE;
   //Verifica se a orientação está subindo ou descendo
   if(orient == UP){
      typeDeal = BUY;
   }else if(orient == DOWN){
      typeDeal = SELL;
   }
   
   return realizeDealsOrders(orderType, typeDeal, volume, limitPrice, stopLoss, takeProfit, magicNumber, duration);
   //getHistory();
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

string verifyPower(POWER power){
   if(power == ON){
      return "ON";
   }else{
      return "OFF";
   }
}

void closePositionInLoss(){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      ulong ticket = PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(i, magicNumber)){
          double profit = PositionGetDouble(POSITION_PROFIT);
          if(profit < 0){
            closeBuyOrSell(i);
          }
      } 
   }
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
            closeBuyOrSell(i);
          }
      } 
   }
}

bool hasOrderOpen(uint position ){ 
   ulong ticket = OrderGetTicket(position);
   if(OrderSelect(ticket) == true) {
      return true;       
   }
    
   return false;
}

bool hasPositionOpen(int position ){
   // string symbol = PositionGetSymbol(position);
 //   PositionSelect(symbol) == true && _Symbol == symbol
      ulong ticket = PositionGetTicket(position);
    if(PositionSelectByTicket(ticket) == true ) {
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
   int copiedPrice = CopyRates(_Symbol,TIME_FRAME,0,numCandles,candles);
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

string verifyPeriod(ORIENTATION orient){
   if(orient == DOWN){
      return "DOWN";
   }
   if(orient == UP){
      return "UP";
   }
   
   return "MEDIUM";
}

bool verifyIfShadowBiggerThanBody(MqlRates& candle, double points = 0){
   double pointsTotal = calcPoints(candle.low, candle.high);
   if(pointsTotal >= points){
      double pointsShadowLow = 0;
      double pointsShadowHigh = 0;
      double total = pointsTotal * 0.6;
      if(verifyIfOpenBiggerThanClose(candle)){
         pointsShadowHigh = calcPoints(candle.open, candle.high);
         pointsShadowLow = calcPoints(candle.close, candle.low);
      }else if(!verifyIfOpenBiggerThanClose(candle)){
         pointsShadowLow = calcPoints(candle.open, candle.low);
         pointsShadowHigh = calcPoints(candle.close, candle.high);
      }
   
      double pointsCandle = pointsTotal - (pointsShadowLow + pointsShadowHigh);
      return pointsShadowHigh > pointsCandle + pointsShadowLow || pointsShadowLow > pointsCandle + pointsShadowHigh ;
   }
   
   return false;
}

ORIENTATION verifyValidCandle(MqlRates& candle, double points = 0){
   double pointsCandle = calcPoints(candle.close, candle.open);
   double pointsShadow = calcPoints(candle.low, candle.high);
   
   if(points == 0 || pointsCandle >= points){
      if(MathAbs(pointsCandle-pointsShadow) < pointsCandle){
         if(verifyIfOpenBiggerThanClose(candle)){
            return DOWN;
         }else if(!verifyIfOpenBiggerThanClose(candle)){
            return UP;
         }
      }
   }

   return MEDIUM;
}

void protectPositions(double points = 0){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      moveStopToZeroPlusPoint(i, points);
   }
}


void closePositionByType(ENUM_POSITION_TYPE type, int i){
   if(hasPositionOpen(i)){
      ulong ticket = PositionGetTicket(i);
      PositionSelectByTicket(ticket);
      ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
      if(verifyMagicNumber(i, magicNumber) && PositionGetInteger(POSITION_TYPE) == type){
            closeBuyOrSell(i);
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

void closeAll(){
   int pos = PositionsTotal() - 1;
   for(int i = pos; i >= 0; i--)  {
      if(hasPositionOpen(i)){
         ulong ticket = PositionGetTicket(i);
         PositionSelectByTicket(ticket);
         ulong magicNumber = PositionGetInteger(POSITION_MAGIC);
         if(verifyMagicNumber(i, magicNumber)){
            closeBuyOrSell(i);
         }
      }
   }
}

int daysDiff(datetime startedDatetimeRobot){
   MqlDateTime structDate, structActual;
   datetime actualTime = TimeCurrent();
   
   TimeToStruct(actualTime, structActual);
   TimeToStruct(startedDatetimeRobot, structDate);
   return (structActual.day_of_year - structDate.day_of_year);
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

color pressButtonColor(bool var, color primary = clrBlue, color secundary =  clrBlueViolet){
   return (var == true ? primary : secundary);
}

void instanciateBorder(BordersOperation& borders){
     borders.max = 0;
     borders.min = 0;
     borders.central = 0;
     borders.instantiated = false;
     borders.orientation = MEDIUM;
}

void generateButtons(){

      createButton("btnCloseProfit", 20, 450, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar com lucro.", clrWhite, clrRed, clrRed, false);
      createButton("btnCloseLoss", 230, 450, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar com Perda.", clrWhite, clrRed, clrRed, false);

      createButton("btnCloseBuy", 20, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Compras", clrWhite, clrRed, clrRed, false);
      createButton("btnCloseSell", 230, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Vendas", clrWhite, clrRed, clrRed, false);
      createButton("btnCloseAll", 440, 400, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Fechar Negociacoes", clrWhite, clrRed, clrRed, false);
      
    
       createButton("btnMoveStop", 20, 350, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Proteger Negociações", clrWhite, clrGreen, clrGreen, false);
      createButton("btnBuy", 230, 350, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Criar " + IntegerToString(NUMBER_ROBOTS) +" Robôs de Compra", clrWhite, clrGreen, clrGreen, false);
      createButton("btnSell", 440, 350, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Criar " + IntegerToString(NUMBER_ROBOTS) +" Robôs de Venda", clrWhite, clrGreen, clrGreen, false);
     
      createButton("btnDoubleVol", 20, 300, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Multiplicar Volume por 2", clrWhite, clrBlue, clrBlue, false);
      createButton("btnDivVol", 230, 300, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Dividir Volume por 2", clrWhite, clrBlue, clrBlue, false);
      createButton("btnResetVol", 440, 300, 200, 30, CORNER_LEFT_LOWER, 12, "Arial", "Resetar Volume", clrWhite, clrBlue, clrBlue, false);
     
}
