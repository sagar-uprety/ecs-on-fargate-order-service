const express = require("express");
const app = express();
const axios = require("axios"); // for making HTTP requests to other microservices
const uuid = require("uuid"); // for generating random IDs
const port = 3002; // Replace with your desired port

const { DynamoDBClient, DeleteItemCommand } = require("@aws-sdk/client-dynamodb");
const {
  PutCommand,
  ScanCommand,
  GetCommand,
  DynamoDBDocumentClient,
} = require("@aws-sdk/lib-dynamodb");

const awsRegion = process.env.awsRegion || "us-east-2";
const dynamodbTableName = process.env.dynamodbTableName || "ecs-orders-ms";

const client = new DynamoDBClient({ region: awsRegion });
const docClient = DynamoDBDocumentClient.from(client);

const userServiceURL = process.env.userServiceURL || "http://localhost:3000";
const productServiceURL =
  process.env.productServiceURL || "http://localhost:3001";

// Middleware and configuration
app.use(express.urlencoded({ extended: true }));
app.set("view engine", "ejs");

// Sample route for listing products and buying them
app.get("/orders/shop", async (req, res) => {
  try {
    // Fetch product list from the product microservice
    const productsResponse = await axios.get(`${productServiceURL}/products`);
    // Render the EJS template with the product list
    res.render("shop", { products: productsResponse.data });
  } catch (error) {
    console.error(error);
    res.status(500).send("Error fetching products.");
  }
});

// Handle the buy button click and create an order
app.post("/orders/create", async (req, res) => {
  try {
    const { productId, productName, price } = req.body;
    const user = await getRandomUser(); // Call user microservice to get a random user
    // Generate random order data
    const order = {
      id: uuid.v4(),
      buyerId: user.id,
      buyerName: user.name,
      buyerAddress: user.address,
      productId,
      productName,
      price: parseFloat(price),
      orderDate: new Date().toISOString,
      paymentMethod: getRandomPaymentMethod(),
    };

    const command = new PutCommand({
      TableName: dynamodbTableName,
      Item: order,
    });

    try {
      await docClient.send(command);
      console.log(`Created order with ID ${order.id} for Product ID: ${productId} into DynamoDB`);
    } catch (error) {
      console.error(
        `Error inserting products with ID ${productId}: ${error.message}`
      );
    }
    res.send(`Order Created Successfully with Order ID : ${order.id}`);
  } catch (error) {
    console.error(error);
    res.status(500).send("Error creating the order.");
  }
});

// Sample route for viewing orders
app.get("/orders", async (req, res) => {
  try {
    const ordersData = await checkIfDataExists();
    res.json(ordersData);
  } catch (error) {
    console.error(`Error: ${error.message}`);
  }
});

//Delete Route
app.get("/orders/delete/:id", async (req, res) => {
  const orderId = req.params.id;

  const command = new DeleteItemCommand({
    TableName: dynamodbTableName,
    Key: {
      id: { S: orderId }, // Assuming the "id" is a string
    },
  });

  try {
    const response = await docClient.send(command);
    console.log(`Deleted order with ID ${orderId} from DynamoDB`);
    res.send(`Order with ID ${orderId} deleted successfully`);
  } catch (error) {
    console.error(`Error deleting order with ID ${orderId}: ${error.message}`);
    res.status(500).send(`Error deleting order with ID ${orderId}`);
  }
});

// Helper function to get a random user (call your user microservice here)
async function getRandomUser() {
  // Implement logic to fetch a random user from your user microservice
  try {
    const users = await axios.get(`${userServiceURL}/users`);
    if (!users.data || users.data.length === 0) {
      return null; // Handle the case when no users are available.
    }

    // Pick a random user from the list.
    const randomIndex = Math.floor(Math.random() * users.data.length);
    const randomUser = users.data[randomIndex];
    return randomUser;
  } catch (error) {
    console.error("Error fetching random user:", error);
    throw error; // You can handle or log the error as needed.
  }
}

// Helper function to get a random payment method
function getRandomPaymentMethod() {
  const paymentMethods = ["COD", "Card", "PayPal"];
  const randomIndex = Math.floor(Math.random() * paymentMethods.length);
  return paymentMethods[randomIndex];
}

async function checkIfDataExists() {
  const scanCommand = new ScanCommand({
    TableName: dynamodbTableName,
  });

  const response = await docClient.send(scanCommand);
  return response.Items || [];
}

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
