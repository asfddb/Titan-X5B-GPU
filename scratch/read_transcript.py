import sys
import json

def read_transcript(path, start_step=0):
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            try:
                data = json.loads(line)
                if data.get("source") == "MODEL" and data.get("type") == "PLANNER_RESPONSE":
                    step = int(data.get("step_index", 0))
                    if step >= start_step:
                        print(f"=== STEP {step} ===")
                        print(data.get("content"))
                        print("\n" + "="*40 + "\n")
            except Exception as e:
                pass

if __name__ == "__main__":
    if len(sys.argv) > 1:
        path = sys.argv[1]
        start_step = int(sys.argv[2]) if len(sys.argv) > 2 else 0
        read_transcript(path, start_step)
    else:
        print("Usage: python read_transcript.py <path_to_transcript.jsonl> [start_step]")
