import subprocess
import os

if __name__ == "__main__":

  f = open("mylog.txt", "a")

  for k in range(1,4):

    for write_buffer_size_i in [1,2,4,8,16,32,64]:
      for block_size_i in range(1,33):

        num_key = 10000000
        write_buffer_size = write_buffer_size_i * 1024 * 1024
        block_size = block_size_i * 1024

        f.write('./out-static/db_bench --benchmarks=fillrandom,stats,readrandom,stats --num=' + str(num_key) + ' --block_size=' + str(block_size) + ' --write_buffer_size=' + str(write_buffer_size) + '\n')
        f.flush()

        subprocess.call(['./out-static/db_bench', '--benchmarks=fillrandom,stats,readrandom,stats', '--num=' + str(num_key), '--block_size=' + str(block_size), '--write_buffer_size=' + str(write_buffer_size)], stdout=f)