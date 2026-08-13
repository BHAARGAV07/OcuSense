from fastapi import FastAPI

app = FastAPI(
    title="OcuSense API",
    version="1.0.0",
    description="FastAPI backend for the OcuSense application.",
)


@app.get("/")
async def root() -> dict:
    return {"message": "Welcome to OcuSense API"}


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
