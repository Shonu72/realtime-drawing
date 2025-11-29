#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:3000/api"

echo -e "${BLUE}🧪 Testing Realtime Drawing Backend API${NC}\n"

# Test 1: Health Check
echo -e "${YELLOW}1. Testing Health Check...${NC}"
curl -s http://localhost:3000/health | jq .
echo -e "\n"

# Test 2: Register User
echo -e "${YELLOW}2. Registering a new user...${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123456",
    "name": "Test User"
  }')

echo "$REGISTER_RESPONSE" | jq .

# Extract token
TOKEN=$(echo "$REGISTER_RESPONSE" | jq -r '.token // empty')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo -e "${YELLOW}⚠️  Registration might have failed or user already exists. Trying login...${NC}"
  LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{
      "email": "test@example.com",
      "password": "test123456"
    }')
  TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token // empty')
  echo "$LOGIN_RESPONSE" | jq .
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo -e "${YELLOW}❌ Could not get authentication token. Please check if server is running.${NC}"
  exit 1
fi

echo -e "\n${GREEN}✅ Token obtained: ${TOKEN:0:20}...${NC}\n"

# Test 3: Get Current User
echo -e "${YELLOW}3. Getting current user info...${NC}"
curl -s -X GET "$BASE_URL/auth/me" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo -e "\n"

# Test 4: Create Board
echo -e "${YELLOW}4. Creating a new board...${NC}"
BOARD_RESPONSE=$(curl -s -X POST "$BASE_URL/boards" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Board",
    "description": "This is a test board",
    "isPublic": true,
    "settings": {
      "enableChat": true,
      "enableReplay": true
    }
  }')

echo "$BOARD_RESPONSE" | jq .

BOARD_ID=$(echo "$BOARD_RESPONSE" | jq -r '.board._id // empty')

if [ -z "$BOARD_ID" ] || [ "$BOARD_ID" == "null" ]; then
  echo -e "${YELLOW}⚠️  Could not create board. Trying to get existing boards...${NC}"
  MY_BOARDS=$(curl -s -X GET "$BASE_URL/boards/my-boards" \
    -H "Authorization: Bearer $TOKEN")
  echo "$MY_BOARDS" | jq .
  BOARD_ID=$(echo "$MY_BOARDS" | jq -r '.boards[0]._id // empty')
fi

if [ -n "$BOARD_ID" ] && [ "$BOARD_ID" != "null" ]; then
  echo -e "\n${GREEN}✅ Board ID: $BOARD_ID${NC}\n"
  
  # Test 5: Get Board Details
  echo -e "${YELLOW}5. Getting board details...${NC}"
  curl -s -X GET "$BASE_URL/boards/$BOARD_ID" \
    -H "Authorization: Bearer $TOKEN" | jq .
  echo -e "\n"
  
  # Test 6: Get Board Strokes
  echo -e "${YELLOW}6. Getting board strokes...${NC}"
  curl -s -X GET "$BASE_URL/boards/$BOARD_ID/strokes" \
    -H "Authorization: Bearer $TOKEN" | jq .
  echo -e "\n"
else
  echo -e "${YELLOW}⚠️  No board ID available for further tests${NC}\n"
fi

# Test 7: Get User's Boards
echo -e "${YELLOW}7. Getting user's boards...${NC}"
curl -s -X GET "$BASE_URL/boards/my-boards" \
  -H "Authorization: Bearer $TOKEN" | jq .
echo -e "\n"

echo -e "${GREEN}✅ API Tests Complete!${NC}"
echo -e "${BLUE}💡 To test WebSocket, use a tool like Postman or create a Socket.IO client${NC}"

