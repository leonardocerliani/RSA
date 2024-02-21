# %%

import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# %%

N=100

x = np.random.randn(N)
y = 0.7*x + np.random.randn(N)

p = sns.histplot(x=x, y=y)

plt.show()


# %%
