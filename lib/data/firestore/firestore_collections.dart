import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/category_model.dart';
import 'models/counter_model.dart';
import 'models/customer_model.dart';
import 'models/daily_close_model.dart';
import 'models/held_bill_model.dart';
import 'models/product_code_model.dart';
import 'models/product_model.dart';
import 'models/sale_model.dart';
import 'models/stock_movement_model.dart';
import 'models/user_model.dart';

class FirestoreCollections {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static CollectionReference<UserModel> users = db
      .collection('users')
      .withConverter<UserModel>(
        fromFirestore: UserModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );

  static CollectionReference<CategoryModel> categories = db
      .collection('categories')
      .withConverter<CategoryModel>(
        fromFirestore: CategoryModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );

  static CollectionReference<ProductModel> products = db
      .collection('products')
      .withConverter<ProductModel>(
        fromFirestore: ProductModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );

  static CollectionReference<ProductCodeModel> productCodes = db
      .collection('productCodes')
      .withConverter<ProductCodeModel>(
        fromFirestore: ProductCodeModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );

  static CollectionReference<CustomerModel> customers = db
      .collection('customers')
      .withConverter<CustomerModel>(
        fromFirestore: CustomerModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );

  static CollectionReference<SaleModel> sales = db
      .collection('sales')
      .withConverter<SaleModel>(
        fromFirestore: SaleModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );

  static CollectionReference<HeldBillModel> heldBills = db
      .collection('heldBills')
      .withConverter<HeldBillModel>(
        fromFirestore: HeldBillModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );

  static CollectionReference<StockMovementModel> stockMovements = db
      .collection('stockMovements')
      .withConverter<StockMovementModel>(
        fromFirestore: StockMovementModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );

  static CollectionReference<DailyCloseModel> dailyCloses = db
      .collection('daily_closes')
      .withConverter<DailyCloseModel>(
        fromFirestore: DailyCloseModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );

  static CollectionReference<CounterModel> counters = db
      .collection('counters')
      .withConverter<CounterModel>(
        fromFirestore: CounterModel.fromFirestore,
        toFirestore: (model, _) => model.toFirestore(),
      );
}
