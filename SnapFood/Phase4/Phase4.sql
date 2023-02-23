--1
SELECT "User"* From "Order" inner join "User" on "Order"."ForCustomer" = "User"."Id" 
Where "Order"."DeliveredTime" >= ... and "Order"."DeliveredTime" <= ...
UNION
Select "User".* from "Order" inner join "User" on "Order"."DeliveredBy" = "User"."Id"
Where "Order"."DeliveredTime" >= ... and "Order"."DeliveredTime" <= ...;

-- 2
select "DeliveredBy" from "Order" o where ("DeliveredTime" - "OrderDate")/60 = ...

--3
Select * from "Order" inner join "DiscountCode" on "Order"."DiscountCode" = "DiscountCode"."Id"
Where "DiscountCode"."CeilPercentage" <= ...

-- 4
select "Name" from "Food" f where "Pirce" >= ... and "Pirce" <= ...
intersect 
select "Name" from "OrderFoods" of2 inner join "Food" f ON of2."FoodID" = f.id join "Order" o ON of2."OrderID" = o.id 
join "Review" r on o.id = r."ForOrder" group by f."Name" having avg("Rating") >= ... and avg("Rating") <= ...

--5
Select "Type", SUM("Food"."Price")  From "OrderFoods" inner join "Order" on "OrderFoods"."OrderID" = "Order"."id"
join "Food" on "OrderFoods"."FoodID" = "Food"."id"
Group By "Type"
Where "Order"."ForCustomer" = ...;

-- 6
SELECT "User"."FirstName" || ' ' || "User"."LastName" AS name, d.rate AS rate FROM (
    SELECT "Delivery"."Id" AS id, AVG("Review"."DeliveryRate"::int) AS rate FROM "Delivery"
    INNER JOIN "Order" ON "Order"."DeliveredBy" = "Delivery"."Id"
    INNER JOIN "Review" ON "Review"."ForOrder" = "Order".id
    INNER JOIN "User" ON "User"."Id" = "Delivery"."Id"
    GROUP BY "Delivery"."Id") d
INNER JOIN "User" ON d.id = "User"."Id"

-- 7
SELECT "Food"."ForBranch" AS branch_id, SUM("Order"."FinalPriceAfterDiscount") AS income FROM "Order"
INNER JOIN "OrderFoods" ON "Order".id = "OrderFoods"."OrderID"
INNER JOIN "Food" ON "OrderFoods"."FoodID" = "Food".id
WHERE "Food"."ForResturant" = ...
GROUP BY "Food"."ForBranch"
ORDER BY income

-- 8
SELECT "Food"."Name" as "FoodName", "Resturant"."Name" as "ResturantName" FROM "Food"
INNER JOIN "Resturant" ON "Food"."ForResturant" = "Resturant".id
WHERE "Food"."InStock" = 0 AND "Resturant"."Name" LIKE '...%'

-- 9
CREATE VIEW food_report AS
SELECT "Food"."Name" AS "FoodName", "Resturant"."Name" AS "ResturantName" FROM (
    SELECT "Food".id AS food_id, "Food"."ForResturant" AS resturant_id FROM "Food"
    GROUP BY "Food".id, "Food"."ForResturant"
    HAVING SUM("Food"."InStock") = 10
    INTERSECT
    SELECT "Food".id AS food_id, "Food"."ForResturant" AS resturant_id FROM "Order"
    INNER JOIN "OrderFoods" ON "OrderFoods"."OrderID" = "Order".id
    INNER JOIN "Food" On "OrderFoods"."FoodID" = "Food".id
    WHERE "Order"."OrderDate" > NOW() - INTERVAL '5 DAYS'
    GROUP BY "Food"."id", "Food"."ForResturant"
    HAVING COUNT(*) = 20
) result_foods
INNER JOIN "Food" ON result_foods.food_id = "Food".id
INNER JOIN "Resturant" ON result_foods.resturant_id = "Resturant".id

-- 10
CREATE OR REPLACE FUNCTION zero_stock_checker()
  RETURNS trigger AS 
$BODY$
BEGIN
  IF (NEW.InStock = 0) THEN
    UPDATE Food SET InStock = 0 WHERE ForResturant = NEW.ForResturant;
  END IF;
  RETURN NEW;
end
$BODY$
  LANGUAGE 'plpgsql' SECURITY INVOKER
;

CREATE TRIGGER stock_zeroer AFTER UPDATE ON "Food" 
FOR EACH ROW EXECUTE PROCEDURE zero_stock_checker()

-- 11
CREATE ASSERTION check_foods
CHECK (NOT EXISTS (
    SELECT SUM(InStock) as stock FROM Food
    GROUP BY name, ForResturant
    HAVING stock = 0
))