from fastapi import FastAPI

from app.api.routes.goals import router as goals_router

app = FastAPI()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


app.include_router(goals_router)
