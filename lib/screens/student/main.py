import argparse
import json
import sys

CMD_SYS_VERSION = 0
CMD_EXECUTE_CODE = 1

def run(command):
    if command["cmd"] == CMD_SYS_VERSION:
        return {
            "sys.version": sys.version,
        }
    
    if command["cmd"] == CMD_EXECUTE_CODE:
        try:
            # Capture the output of print statements
            import io
            import sys
            
            # Redirect stdout to capture print output
            old_stdout = sys.stdout
            redirected_output = sys.stdout = io.StringIO()
            
            # Execute the code
            exec(command["code"])
            
            # Get the captured output
            output = redirected_output.getvalue()
            
            # Restore stdout
            sys.stdout = old_stdout
            
            return {"output": output}
        except Exception as e:
            return {"exception": str(e)}
    
    else:
        return {"error": "Unknown command."}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--uuid")
    args = parser.parse_args()
    stream_start = f"`S`T`R`E`A`M`{args.uuid}`S`T`A`R`T`"
    stream_end = f"`S`T`R`E`A`M`{args.uuid}`E`N`D`"
    while True:
        cmd = input()
        cmd = json.loads(cmd)
        try:
            result = run(cmd)
        except Exception as e:
            result = {"exception": e.__str__()}
        result = json.dumps(result)
        print(stream_start + result + stream_end)