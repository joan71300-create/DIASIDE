import asyncio
import httpx
import hashlib

async def check_status():
    url = "https://web-production-bd395.up.railway.app/api/v1/status.json"
    token = "3893UDJDJ29ZJFJSI2DJS"
    headers = {"api-secret": hashlib.sha1(token.encode()).hexdigest()}
    
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.get(url, headers=headers)
            print(f"Status: {resp.status_code}")
            print(f"Body: {resp.text[:500]}")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_status())
