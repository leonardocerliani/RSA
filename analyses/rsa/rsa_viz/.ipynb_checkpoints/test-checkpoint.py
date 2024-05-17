import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

plt.ion()  # Set interactive mode
plt.switch_backend('agg')  # Set Agg backend

N = 100

x = np.random.randn(N)
y = 0.7 * x + 0.3 * np.random.randn(N)


sns.scatterplot(x=x, y=y)


import matplotlib.pyplot as plt
import numpy as np


x = np.linspace(0, 20, 100)
plt.plot(x, np.sin(x))
plt.show()