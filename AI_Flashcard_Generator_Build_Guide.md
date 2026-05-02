# AI Flashcard Generator: Technical Build Guide

*How to make an AI app that turns documents into genuinely useful flashcards*

---

## Quick Answer

**Yes, this is very buildable** — and it's already a real, validated market. Existing apps like Quizlet, Revisely, AnkiDecks, Scholarly, Limbiks, MintDeck, and RemNote all ship this exact feature, with users on the order of millions and proven $5–15/mo subscription pricing. None of them runs fully on-device, and most have weak language support outside English. That's your opening.

The build itself splits into **three hard problems**, in order of difficulty:

1. **Document parsing** — extracting clean text from PDFs, PowerPoint, Word, etc.
2. **Concept extraction** — figuring out what's *actually worth* learning vs. filler
3. **Card generation** — producing flashcards that follow proven pedagogy

Most existing apps nail #1, half-solve #2, and almost none do #3 well. The third is where you compete.

---

## Part 1: How The Existing Apps Work (Competitive Analysis)

Before designing yours, it's worth understanding what's already shipping:

| App | Approach | Where It Wins | Where It Fails |
|---|---|---|---|
| **Quizlet** | Cloud LLM, paste/upload | Brand, network effects | Generic cards, paywall heavy |
| **AnkiDecks** | Cloud LLM, exports to Anki | Anki integration, image occlusion | Cloud-only, English-first |
| **Scholarly** | Cloud + RAG | Page citations, study modes | Free tier limited, English-first |
| **Revisely** | Cloud LLM | Clean UI, exam mode | No offline, no regional langs |
| **RemNote** | Notes + flashcards integrated | Workflow integration | Steep learning curve |
| **MintDeck** | Gemini API + FSRS | Solid spaced repetition | Cloud-dependent |
| **Memo.cards** | RAG with citations | Multi-source synthesis | Subscription required |

**The pattern:** Everyone uses cloud APIs (OpenAI, Gemini, Claude). They charge $5–15/mo because inference costs them $0.50–2 per active user. **An on-device version using Gemma 4 has zero marginal cost** — meaning you can charge $4.99 once and still profit, or undercut everyone with a free tier that's actually free.

---

## Part 2: The Document Parsing Problem

Different formats need different extraction strategies. Don't try to convert everything to plain text — you'll lose structure that matters for good flashcards.

### PDF Files

PDFs are the worst case. They come in three flavors:

**Type A: Native text-based PDFs** (lecture slides exported from PowerPoint, textbook PDFs from publishers)
- Use `PDFKit` (iOS) or `PdfRenderer` + `pdfbox-android` (Android)
- Extract text per page with positional info
- Preserve heading hierarchy, bullet points, font sizes
- **This is 60% of student PDFs**

**Type B: Scanned PDFs** (textbook photocopies, scanned handouts)
- Need OCR — Gemma 4's vision model handles this well
- Process page-by-page through the model
- Slower (~3–5 sec/page on E2B) but works offline
- **Quality varies wildly** — warn users about scan quality

**Type C: Mixed PDFs** (slides with diagrams, screenshots, equations)
- Need both text extraction AND vision understanding
- Diagrams should become image-occlusion cards, not text cards
- Math equations are a nightmare — most extraction fails

**Recommended library stack:**

```kotlin
// Android
implementation("com.itextpdf:itext7-core:8.0.4")
implementation("com.tom-roush:pdfbox-android:2.0.27.0")

// For OCR fallback
// (Use Gemma 4 vision instead of bundling Tesseract)
```

```swift
// iOS — PDFKit is built-in
import PDFKit

let pdf = PDFDocument(url: pdfURL)
for i in 0..<pdf.pageCount {
    let page = pdf.page(at: i)
    let text = page?.string  // Returns nil for scanned pages
}
```

### PowerPoint (.pptx)

PPTX files are actually XML inside a zip. You can extract text without Microsoft's libraries:

**Strategy:**
1. Unzip the .pptx file (it's just a ZIP)
2. Parse `ppt/slides/slide*.xml` files
3. Extract text from `<a:t>` elements (the actual text runs)
4. Get speaker notes from `ppt/notesSlides/notesSlide*.xml` — these are GOLD for flashcards
5. Optionally extract slide images for image-occlusion cards

**Why PPTX is the easiest source:** Lecturers structure slides logically — each slide is roughly one concept. The slide title becomes a question topic, bullet points become facts, speaker notes give context. **AnkiDecks and Limbiks are essentially "PPTX flashcard generators" with PDF support tacked on.**

### Word (.docx)

Same trick as PPTX — it's XML in a zip. Use Apache POI (Android) or DocumentKit (iOS), or just unzip and parse `word/document.xml`.

**What matters in DOCX:**
- Heading styles (H1, H2, H3) define hierarchy — flashcard topics
- Bold and italic text often marks key terms
- Tables often contain definitions worth flashcardizing
- Comments and revision marks should be ignored

### Other Formats Worth Supporting

| Format | Effort | Worth It? |
|---|---|---|
| EPUB (e-books) | Low (it's HTML in a zip) | Yes — huge for self-learners |
| Markdown | Trivial | Yes — devs love it |
| HTML web pages | Medium | Yes — saves hours of copy-paste |
| YouTube transcripts | Medium | Yes — viral feature |
| Photos of notes | Built-in via Gemma 4 vision | Yes — biggest UX win |
| Audio lectures | Hard (needs Whisper) | Phase 2 |

---

## Part 3: The "What's Worth Learning" Problem (The Hard One)

This is where 90% of AI flashcard apps fail. They generate technically correct flashcards that are useless for studying.

### Why Naive AI Generation Fails

If you just throw a PDF at an LLM and ask "make flashcards," you get garbage like:

- **Card 1:** Q: What is the title of Chapter 3? A: Cell Biology
- **Card 2:** Q: How many pages does this section have? A: 12
- **Card 3:** Q: What is the first sentence of the introduction? A: [paragraph]
- **Card 4:** Q: What did the author write about in this paragraph? A: [the entire paragraph]

Real students need cards like:

- Q: What process produces ATP in cells?
- A: Cellular respiration in mitochondria.

The difference is **knowing what's testable** vs. what's just text on a page.

### The Atomic Card Principle

Cognitive science research (Michael Nielsen, SuperMemo's Twenty Rules) is unanimous: **good flashcards are atomic.** One fact per card. No exceptions.

**Bad card (compound):**
> Q: What are the causes, symptoms, and treatment methods of diabetes mellitus?

**Good cards (atomic):**
> Q: What hormone is deficient or ineffective in diabetes mellitus?
> A: Insulin.
>
> Q: What is the most common early symptom of Type 2 diabetes?
> A: Increased thirst (polydipsia).
>
> Q: What is the first-line oral medication for Type 2 diabetes?
> A: Metformin.

Your AI must enforce atomicity. This is a prompt engineering problem.

### What Counts as "Testable Knowledge"

Train (or prompt) your AI to recognize these patterns as flashcard-worthy:

1. **Definitions** — "X is defined as..." / "Y refers to..."
2. **Cause-effect relationships** — "X leads to Y because..."
3. **Numerical values** — dates, constants, percentages, formulas
4. **Named concepts** — laws, theorems, principles, named after people
5. **Processes** — sequences of steps
6. **Comparisons** — X vs Y differences
7. **Categories** — taxonomies, classifications
8. **Application of rules** — "When you see X, do Y"

Train it to **ignore** these:

- Filler text (transitions, "in conclusion", "let's discuss")
- Examples that just illustrate (vs. defining)
- Author's commentary or opinions
- Page numbers, references, citations
- Repeated or summary content

---

## Part 4: The Two-Pass Architecture (My Recommended Approach)

This is the architecture that actually produces good cards. It's how the better apps (Memo.cards, Scholarly) work under the hood.

### Pass 1: Concept Extraction

**Input:** Raw extracted text + structure (headings, bullets, etc.)
**Output:** A structured list of "concepts worth knowing"

**Prompt to the model:**

```
You are analyzing study material to identify what's worth memorizing for an exam.

For each section of the document below, identify ONLY:
- Definitions of key terms
- Important facts (dates, numbers, formulas)
- Cause-and-effect relationships
- Named concepts (laws, principles, theorems)
- Processes that must be followed in order
- Comparisons between concepts
- Rules and when to apply them

IGNORE:
- Filler text and transitions
- Examples that only illustrate (unless the example IS the concept)
- Author commentary
- Repeated content

Output as a JSON array of concept objects:
[
  {
    "concept": "the specific testable knowledge",
    "type": "definition|fact|relationship|process|comparison|rule",
    "source_section": "which heading/section it came from",
    "importance": "critical|important|nice-to-know"
  }
]

Document:
[CONTENT]
```

This pass acts as a filter. Out of a 30-page PDF with maybe 12,000 words, you might extract 50–80 concepts. Reviews show ~30–60 cards per 20-page lecture is the sweet spot.

### Pass 2: Card Generation

**Input:** The concept list from Pass 1
**Output:** Atomic flashcards

**Prompt:**

```
Convert each concept below into one or more atomic flashcards.

Rules:
1. Each card tests EXACTLY ONE fact. If a concept has two parts,
   make two cards.
2. Question must be answerable in <10 seconds.
3. Question must make sense without the source document.
4. Avoid yes/no questions unless absolutely necessary.
5. Avoid "list all" questions — break into individual cards.
6. Use the question type that best fits the concept:
   - "What is X?" for definitions
   - "Why does X happen?" for causation
   - "When should you use X?" for rules
   - "What's the difference between X and Y?" for comparisons (but
     keep the comparison atomic — one dimension at a time)
   - Cloze deletion (fill-in-blank) for facts in context
7. Answer should be the shortest correct response.

Output JSON:
[
  {
    "front": "the question",
    "back": "the answer",
    "type": "basic|cloze|reverse",
    "source_concept_id": "links back to Pass 1",
    "difficulty": "easy|medium|hard"
  }
]

Concepts:
[CONCEPTS_FROM_PASS_1]
```

### Why Two Passes Beat One

**One-pass generation** asks the model to do everything: read the document, decide what's important, AND write good cards. It tends to produce too many cards, miss key concepts, and pack too much per card.

**Two-pass generation** separates the editorial decision (what to teach) from the writing decision (how to phrase it). The model can focus on each problem in turn. **This is the single biggest quality lever in the whole system.**

---

## Part 5: Going Beyond — Techniques That Make Cards Genuinely Useful

The two-pass architecture gets you to "decent." These techniques get you to "better than the competition."

### 1. Use Document Structure as a Signal

Don't treat the whole PDF as flat text. Use formatting cues:

- **Bolded terms** are usually flashcardable definitions
- **Headings** define topic boundaries
- **Bulleted lists** under a heading are often parallel facts (good for atomic cards)
- **Tables** are gold — each row is often a comparison card
- **Captioned figures** suggest image-occlusion opportunities
- **Numbered lists** suggest process/sequence cards

A simple but powerful trick: when you see a definition pattern like "**Term**: explanation", auto-generate the card before even asking the LLM. The model handles the messy cases; deterministic rules handle the clean ones.

### 2. Image Occlusion for Diagrams

Anatomy, geography, biology, engineering — diagrams are core. AnkiDecks markets this heavily and med students love it.

**How it works:**
1. Extract images from the document (PPTX, PDF)
2. Use Gemma 4 vision to detect labels in the image
3. Generate cards where each label is masked, asking "what is this?"
4. Render as image with a black box over the answer

**Code sketch:**

```kotlin
// Pseudo-code
val labels = gemma4.detectLabels(image)
for (label in labels) {
    val card = ImageOcclusionCard(
        image = image,
        maskedRegion = label.boundingBox,
        answer = label.text
    )
    cards.add(card)
}
```

This single feature is the reason med students pay AnkiDecks $9.99/mo. It's hard to do well, but it's a huge differentiator.

### 3. Cloze Deletion for Context-Heavy Facts

Cloze cards are sentences with key terms blanked out:

> "Mitochondria produce ATP through the process of {{c1::cellular respiration}}, primarily in the {{c2::matrix}} and {{c3::inner membrane}}."

This works great for:
- Facts that lose meaning out of context
- Foreign language vocabulary in sentences
- Formulas with multiple variables
- Lists where order matters

When the source content is well-written prose, prefer cloze cards over basic Q&A — they preserve context.

### 4. Generate Multiple Card Types Per Concept

For an important concept, generate 2–4 cards from different angles:

For "Photosynthesis converts light energy to chemical energy in plants":

- **Definition:** Q: What is photosynthesis? A: The conversion of light energy to chemical energy in plants.
- **Reverse:** Q: What process converts light energy to chemical energy? A: Photosynthesis.
- **Cloze:** Photosynthesis converts {{c1::light energy}} to {{c2::chemical energy}} in plants.
- **Application:** Q: Why can't animals perform photosynthesis? A: They lack chloroplasts.

This redundancy is intentional — spaced repetition research shows multiple angles strengthen memory traces.

### 5. Source Citations on Every Card

Always link cards back to where they came from in the document:

```json
{
  "front": "What is the powerhouse of the cell?",
  "back": "The mitochondrion",
  "source": {
    "document": "Bio101_Chapter4.pdf",
    "page": 73,
    "section": "Cellular Energy Production",
    "snippet": "...mitochondria are often called the powerhouse..."
  }
}
```

When the user is unsure about a card, they can tap to see the original context. This is also great for trust — users worry about AI hallucinations, and citations are the antidote.

### 6. Difficulty Estimation

Tag each card with estimated difficulty so spaced repetition algorithms (SM-2, FSRS) can schedule them well:

- **Easy:** Definitions of common terms, basic facts
- **Medium:** Relationships, applied rules, formulas
- **Hard:** Multi-step processes, edge cases, comparisons

You can prompt the model to estimate this, or use heuristics: cards with longer answers, technical vocabulary, or multi-clause questions are usually harder.

### 7. Let Users Tune Generation

Give users sliders or toggles:

- **Card density:** Fewer (key concepts only) ↔ More (comprehensive)
- **Question style:** Definitions ↔ Application ↔ Mix
- **Difficulty:** Beginner ↔ Advanced
- **Card types:** Basic / Cloze / Image / Multiple Choice

Different study goals need different decks. A nursing student cramming for boards needs different cards than a casual learner reading a Wikipedia article.

---

## Part 6: Mobile App Architecture for Solo Devs

Here's how to actually build this as a solo developer, end to end.

### Tech Stack

```
┌──────────────────────────────────────────────┐
│  UI: Jetpack Compose (Android) or SwiftUI    │
├──────────────────────────────────────────────┤
│  Document Parsing Layer                      │
│  - PDF: PDFKit / pdfbox-android              │
│  - PPTX: ZipInputStream + XML parsing        │
│  - DOCX: ZipInputStream + XML parsing        │
│  - Images: Gemma 4 vision                    │
├──────────────────────────────────────────────┤
│  Concept Extraction (Pass 1)                 │
│  - Gemma 4 E4B (better reasoning)            │
│  - Function calling → structured JSON        │
│  - Chunking strategy for long docs           │
├──────────────────────────────────────────────┤
│  Card Generation (Pass 2)                    │
│  - Gemma 4 E2B (faster, simpler task)        │
│  - Function calling → card JSON              │
│  - Validation & dedup                        │
├──────────────────────────────────────────────┤
│  Card Storage & Study                        │
│  - Room/SQLite for cards                     │
│  - FSRS algorithm for spaced repetition      │
│  - Local export to Anki .apkg format         │
├──────────────────────────────────────────────┤
│  Export & Sync                               │
│  - Anki .apkg (most important)               │
│  - Quizlet CSV                               │
│  - PDF for printing                          │
└──────────────────────────────────────────────┘
```

### Handling Long Documents (The Chunking Problem)

A 200-page textbook won't fit in any context window. You need to chunk smartly.

**Bad chunking:** Split every 4,000 tokens regardless of content. Splits sentences in half. Concepts get cut.

**Good chunking strategy:**

1. Split at section boundaries (use document structure)
2. If a section is too long, split at paragraph boundaries
3. If a paragraph is too long, split at sentence boundaries
4. Add 100-token overlap between chunks
5. Track which chunk produced which concepts (for source attribution)

Then run Pass 1 on each chunk, accumulate concepts, deduplicate, then run Pass 2.

```python
# Pseudo-code
chunks = smart_chunk(document, target_size=3000)
all_concepts = []

for chunk in chunks:
    concepts = extract_concepts(chunk)
    all_concepts.extend(concepts)

deduped = deduplicate(all_concepts)  # Same concept may appear in multiple chunks
cards = generate_cards(deduped)
```

### On-Device vs Hybrid Approach

You have three options:

**Option A: 100% on-device with Gemma 4**
- Pros: Free for users, private, offline
- Cons: Slower (~30-60 seconds for a 20-page PDF), needs 4GB+ RAM
- Best for: Privacy-conscious users, students with sensitive notes

**Option B: 100% cloud (existing competitors' approach)**
- Pros: Fast, handles huge documents
- Cons: Costs you $0.50–2/user/month, requires subscription
- Best for: VC-backed competitors

**Option C: Hybrid (recommended for solo devs)**
- Local: Document parsing, simple text extraction, fallback for offline
- Cloud (optional): Heavy concept extraction for big docs, premium tier
- Best for: Freemium model — free tier on-device, "pro" tier with cloud speed

For a solo dev targeting a privacy-first wedge, **Option A is the differentiation play.** No competitor offers it.

### File Size Limits to Set

Realistic limits for an on-device app:

| Source | Free Tier | Paid Tier |
|---|---|---|
| PDF text-based | 50 pages | 500 pages |
| PDF scanned | 20 pages | 100 pages |
| PowerPoint | 30 slides | 200 slides |
| Word document | 20 pages | 200 pages |
| Image of notes | 5 images | 50 images |
| Total file size | 10 MB | 100 MB |

Communicate these clearly. Frustrated users delete apps.

---

## Part 7: Quality Assurance — Stopping Bad Cards

Even with two-pass generation, ~10–20% of generated cards will be bad. Build a review step.

### Auto-Detect Bad Cards Before Showing the User

Run validation rules:

```kotlin
fun isBadCard(card: Flashcard): Boolean {
    return when {
        card.front.length > 200 -> true  // Too long
        card.back.length > 300 -> true  // Too long
        card.front.contains("the following") -> true  // Compound
        card.front.contains("all of the") -> true  // List card
        card.front.startsWith("True or false") -> true  // Yes/no
        card.back.length < 3 -> true  // Empty answer
        card.front == card.back -> true  // Identical
        else -> false
    }
}
```

Don't show bad cards. Either regenerate them or skip.

### User-Driven Improvement

Every card needs three actions:

1. **👍 Keep** — User approves, card enters their deck
2. **✏️ Edit** — User refines question or answer
3. **🗑️ Delete** — User removes (and ideally, you learn from it)

Track user deletions per concept type. If users delete 50% of "process" cards, your prompt for processes is wrong.

### The "Did I Learn the Right Thing?" Test

After generating cards, the killer feature is: **"Generate 5 sample exam questions and verify the deck answers them."**

This catches gaps. If your AI generates 40 cards from a chapter but can't answer the chapter's review questions using only those cards, the cards missed something important. This is RAG-style validation against the source document.

---

## Part 8: Monetization

This category has clear price points already validated by the market:

| Tier | Price | What's Included |
|---|---|---|
| Free | $0 | 3 decks/mo, 50 pages/upload, watermark on exports |
| Premium | $4.99/mo or $39/yr | Unlimited decks, 500 pages/upload, no watermark |
| Pro | $9.99/mo or $79/yr | Image occlusion, audio support, multi-language |
| Lifetime | $99 one-time | All Pro features forever — privacy-absolutist appeal |

**Key insight:** Most competitors paywall the export to Anki. Don't. Make Anki export free and unlimited — it's the strongest signal of trust ("I'm not locking you in") and converts more users to paid because they're now invested.

**The Philippines twist:** Price at ₱99/mo or ₱699/yr. With on-device inference, this is still ~95% gross margin. Most competitors can't profitably serve this price point because their cloud inference cost exceeds the revenue.

---

## Part 9: The 90-Day Build Plan

If I were building this as a solo dev starting today:

**Days 1–14: Document parsing**
- Get PDF, PPTX, DOCX text extraction working perfectly
- Handle edge cases (scanned PDFs, password-protected, corrupt files)
- Build a "view what was extracted" debug screen

**Days 15–30: Single-document MVP**
- Implement two-pass generation with Gemma 4 E4B
- Build basic card review UI
- Local SQLite storage with FSRS
- Test on 20 different real documents from real users

**Days 31–45: Card quality push**
- Add atomic card validation
- Implement document-structure heuristics
- Add cloze deletion support
- A/B test prompt variations on a held-out set of documents

**Days 46–60: Polish**
- Anki export (.apkg generation)
- Beautiful onboarding flow
- Image occlusion (if you can fit it)
- Dark mode, accessibility

**Days 61–75: Beta launch**
- TestFlight / Play Store internal testing
- Recruit 50 students for feedback
- Iterate on the cards they delete

**Days 76–90: Public launch**
- Submit to App Store / Play Store
- Launch on Reddit (r/Anki, r/medicalschool, r/GetStudying)
- Product Hunt launch
- Apply for the Gemma Hackathon

---

## Part 10: Why You Could Win This

The flashcard generator space has a structural opportunity:

1. **Every existing app is cloud-based.** Privacy is genuinely valued by med students with patient case notes, lawyers with case files, and students whose lecture slides they don't want trained on.

2. **English bias is universal.** Filipino, Cebuano, Indonesian, Vietnamese students get terrible results. Gemma 4's 140-language support fixes this.

3. **Pricing is too high.** $10/mo for a flashcard generator is steep for emerging markets. On-device + one-time pricing is a real wedge.

4. **The "atomic card" problem is unsolved.** Most existing apps produce mediocre cards. A team that obsesses over Pass 1 + Pass 2 quality can produce noticeably better decks.

5. **The market is large and validated.** AnkiDecks, Quizlet, Scholarly all have real user bases and revenue. You're not creating demand — you're competing on quality and pricing.

The build is hard but tractable for a solo dev in 90 days. The market exists. The differentiation (privacy + on-device + multi-language) is real. The pedagogical research (atomic cards, spaced repetition) is well-documented. **This is one of the best solo-dev opportunities in the on-device AI space.**
