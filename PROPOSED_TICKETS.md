# DIASIDE Development Tickets - Phase 3

Based on a comprehensive scan of the `diaside_mobile` (Flutter) and `app` (FastAPI) codebases, the following tickets are proposed to advance the project towards a production-ready MVP.

## 🧠 AI & Agent Development (Priority: High)

### [AI-003] Multi-turn Context Awareness for Coach (COMPLETED)
- **Status**: ✅ Done
- **Description**: The current `ai_service.py` evaluates queries in isolation. Implement a conversation history buffer (e.g., last 5 messages) passed to the Gemini model to support follow-up questions.
- **Tasks**:
  - Update `AICoachRequest` schema to include `chat_history`. (Done)
  - Modify `GeminiProvider.generate_response` to format history into the prompt. (Done)
  - Update `CoachProvider` in Flutter to persist and send history. (Done)
- **Acceptance Criteria**: The coach correctly answers "And what about 2 hours later?" after a question about insulin timing.

### [AI-004] RAG Integration for Medical Knowledge
- **Description**: Connect the coach to a verified medical knowledge base (e.g., PDF guidelines, JSON data) using RAG to reduce hallucinations and provide sourced answers.
- **Tasks**:
  - Set up a vector store (e.g., ChromaDB or FAISS).
  - Ingest diabetes guidelines documents.
  - Implement retrieval logic in `ai_service.py` before querying Gemini.
- **Acceptance Criteria**: Coach answers cite specific guidelines (e.g., "According to ADA guidelines...").

### [AI-005] Persona & Tone Refinement
- **Description**: Evaluation scores show variability in "Empathy". Fine-tune the system prompt to enforce a consistent, supportive, and non-judgmental persona.
- **Tasks**:
  - Refine system prompt in `app/core/prompts.py` (create if missing).
  - Add "few-shot" examples of empathetic responses to the prompt.
  - Re-run `DIASIDE-EXPERT-FINAL-V4` evaluation to verify score improvement.
- **Acceptance Criteria**: Empathy scores consistently above 4/5 on Opik.

## 📱 Frontend Development (Flutter) (Priority: Medium)

### [FE-006] Design System Implementation
- **Description**: The current UI is functional but basic. Implement a cohesive design system (colors, typography, spacing) defined in `app_colors.dart` and a new `app_theme.dart`.
- **Tasks**:
  - Define primary, secondary, error, and background colors.
  - Create standard text styles (H1, H2, Body, Caption).
  - Refactor `DiasideButton` and `DiasideCard` to use the new theme.
  - Apply theme to `DashboardScreen`, `CoachScreen`, etc.
- **Acceptance Criteria**: All screens share a consistent visual identity matching the "DIASIDE" brand.

### [FE-007] Real-time Glucose Charting
- **Description**: `GlucoseChart` currently displays static or simple data. Connect it to a stream of glucose readings (mocked or real) for dynamic updates.
- **Tasks**:
  - Implement a `GlucoseRepository` with a `watchGlucose()` method.
  - Update `GlucoseProvider` to expose a `Stream<List<GlucoseReading>>`.
  - Optimize `GlucoseChart` to handle frequent updates without full rebuilds.
- **Acceptance Criteria**: The chart updates automatically when a new reading is added.

### [FE-008] Offline Data Persistence (Isar/Hive)
- **Description**: Users must be able to log meals and glucose without internet. Implement local storage that syncs when online.
- **Tasks**:
  - Integrate `isar` or `hive_flutter`.
  - Create local models for `Meal` and `Glucose`.
  - Implement a "Sync Service" to push local changes to the backend when connection is restored.
- **Acceptance Criteria**: App functions fully in airplane mode; data appears on backend after reconnecting.

### [FE-009] Accessibility Improvements
- **Description**: Ensure the app is accessible, especially for users with visual impairments (diabetic retinopathy).
- **Tasks**:
  - Add semantic labels to all buttons and charts.
  - Verify sufficient color contrast (WCAG AA).
  - Support dynamic text sizing.
- **Acceptance Criteria**: App passes a basic accessibility audit (e.g., TalkBack/VoiceOver works meaningfully).

## ⚙️ Backend & Infrastructure (Priority: Medium)

### [BE-010] Authentication Hardening
- **Description**: Review `api/auth.py` and `core/security.py`. Ensure JWTs are handled securely (HTTP-only cookies preferred or secure storage on mobile) and implement refresh tokens.
- **Tasks**:
  - Implement access/refresh token rotation.
  - Add rate limiting to login endpoints to prevent brute force.
  - Validate password strength on registration.
- **Acceptance Criteria**: Security audit shows no critical vulnerabilities in auth flow.

### [BE-011] Database Migrations (Alembic)
- **Description**: Ensure reproducible database schema changes. Set up Alembic for the `app/models` definitions.
- **Tasks**:
  - Initialize Alembic (`alembic init`).
  - Configure `env.py` to import SQLAlchemy models.
  - Generate initial migration script.
- **Acceptance Criteria**: Can recreate the database schema from scratch using `alembic upgrade head`.

### [BE-012] Backend Unit & Integration Tests
- **Description**: Test coverage is low. Add `pytest` tests for critical endpoints (auth, glucose logging, coach chat).
- **Tasks**:
  - Create `tests/test_auth.py`, `tests/test_glucose.py`.
  - Mock external services (Gemini, DB) for unit tests.
  - Setup a CI pipeline (GitHub Actions) to run tests on push.
- **Acceptance Criteria**: >80% code coverage on core logic.

### [BE-013] Docker Deployment Setup
- **Description**: Prepare the application for deployment (e.g., to Render, Fly.io, or AWS).
- **Tasks**:
  - Create a multi-stage `Dockerfile` for the FastAPI app.
  - Create a `docker-compose.prod.yml` including the app and a Postgres DB.
  - Configure environment variables for production (disable debug, secure keys).
- **Acceptance Criteria**: `docker-compose up` launches a fully functional production-like environment.

## 👁️ Vision Features (Priority: Low/Experimental)

### [VIS-014] Mobile Food Recognition Integration
- **Description**: The backend has `vision_service.py`, but the mobile app lacks the camera flow to use it.
- **Tasks**:
  - Implement a camera/gallery picker in `MealCaptureScreen`.
  - Send the image to the backend's vision endpoint.
  - tailored the response (carbs/calories) to pre-fill the `MealEntryScreen`.
- **Acceptance Criteria**: Taking a photo of a banana auto-fills "Banana, ~25g carbs".
