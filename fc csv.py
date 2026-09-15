#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Dec 23 08:23:13 2025

@author: corawoo
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from joblib import load

 
save_dir = '/Users/....'
plot_dir = os.path.join(save_dir, 'plots')
os.makedirs(save_dir, exist_ok=True)
os.makedirs(plot_dir, exist_ok=True)

 
(temp_data, subj_con, con_np, tril_idx, FC_data1, FC_data2) = load('task_wpli 0.2-0.6 G2 812.joblib')

 
ch_names = temp_data.ch_names
n_channels = len(ch_names)

 
print(f"FC_data1[0] : {FC_data1[0].shape}")
print(f"FC_data2[0] : {FC_data2[0].shape}")
print(f"通道数量: {n_channels}")

 
FC_all1 = np.stack(FC_data1, axis=0)
FC_all2 = np.stack(FC_data2, axis=0)

print(f"FC_all1 : {FC_all1.shape}")
print(f"FC_all2 : {FC_all2.shape}")

 
if FC_all1.shape[1] == n_channels * n_channels or FC_all1.shape[1] == n_channels * (n_channels - 1) // 2:
 
    print("Vectorized connection data have been detected and are being reconstructed into matrix form....")
    
 
    if tril_idx is not None and len(tril_idx) == 2:
        rows, cols = tril_idx
        print(f"  tril_idx: rows={len(rows)}, cols={len(cols)}")
    else:
 
        rows, cols = np.tril_indices(n_channels, -1)
        print(f" rows={len(rows)}, cols={len(cols)}")
    
 
    FC_all1_matrices = []
    FC_all2_matrices = []
    
    for subj_idx in range(FC_all1.shape[0]):
  
        matrix1 = np.zeros((n_channels, n_channels))
        matrix2 = np.zeros((n_channels, n_channels))
        
 
        if FC_all1.shape[1] == len(rows):   
            matrix1[rows, cols] = FC_all1[subj_idx]
            matrix1[cols, rows] = FC_all1[subj_idx]   
            
            matrix2[rows, cols] = FC_all2[subj_idx]
            matrix2[cols, rows] = FC_all2[subj_idx]   
        elif FC_all1.shape[1] == n_channels * n_channels:   
            matrix1 = FC_all1[subj_idx].reshape(n_channels, n_channels)
            matrix2 = FC_all2[subj_idx].reshape(n_channels, n_channels)
        
        FC_all1_matrices.append(matrix1)
        FC_all2_matrices.append(matrix2)
    
 
    FC_all1 = np.stack(FC_all1_matrices, axis=0)
    FC_all2 = np.stack(FC_all2_matrices, axis=0)
    
    print(f"  FC_all1  : {FC_all1.shape}")
    print(f"  FC_all2  : {FC_all2.shape}")
elif FC_all1.ndim == 3 and FC_all1.shape[1] == n_channels and FC_all1.shape[2] == n_channels:
    print("The data is already in matrix form and requires no reconstruction.")
else:
    print(f" : {FC_all1.shape}")

 
print("\n ...")

for subj_idx in range(FC_all1.shape[0]):
 
    fc_matrix1 = FC_all1[subj_idx]
    fc_matrix2 = FC_all2[subj_idx]
    
 
    if fc_matrix1.shape == (n_channels, n_channels) and fc_matrix2.shape == (n_channels, n_channels):
 
        df1 = pd.DataFrame(fc_matrix1, index=ch_names, columns=ch_names)
        df2 = pd.DataFrame(fc_matrix2, index=ch_names, columns=ch_names)
        
 
        df1.to_csv(os.path.join(save_dir, f'subject_{subj_idx+1:03d}_condition1_fc.csv'))
        df2.to_csv(os.path.join(save_dir, f'subject_{subj_idx+1:03d}_condition2_fc.csv'))
        
        print(f"  {subj_idx+1}  ")
        
        
        print(f" {subj_idx+1}  ...")
        
 
        fig, axes = plt.subplots(1, 2, figsize=(20, 8))
        
 
        vmin = min(fc_matrix1.min(), fc_matrix2.min())
        vmax = max(fc_matrix1.max(), fc_matrix2.max())
        
 
        im1 = axes[0].imshow(fc_matrix1, cmap='hot', aspect='auto', vmin=vmin, vmax=vmax)
        axes[0].set_title(f'Subject {subj_idx+1}: Condition 1 (EC)', fontsize=16)
        axes[0].set_xlabel('Channels', fontsize=12)
        axes[0].set_ylabel('Channels', fontsize=12)
        
 
        plt.colorbar(im1, ax=axes[0], fraction=0.046, pad=0.04)
        
 
        im2 = axes[1].imshow(fc_matrix2, cmap='hot', aspect='auto', vmin=vmin, vmax=vmax)
        axes[1].set_title(f'Subject {subj_idx+1}: Condition 2 (EO)', fontsize=16)
        axes[1].set_xlabel('Channels', fontsize=12)
        axes[1].set_ylabel('Channels', fontsize=12)
        
 
        plt.colorbar(im2, ax=axes[1], fraction=0.046, pad=0.04)
        
        plt.tight_layout()
        
 
        plt.savefig(os.path.join(plot_dir, f'subject_{subj_idx+1:03d}_fc_matrices.png'), dpi=300, bbox_inches='tight')
        plt.close()
        
    else:
        print(f"  {subj_idx+1}  : condition1={fc_matrix1.shape}, condition2={fc_matrix2.shape}")

 
print("\n...")

if FC_all1.ndim == 3 and FC_all1.shape[1] == n_channels and FC_all1.shape[2] == n_channels:
 
    FC_mean1 = FC_all1.mean(axis=0)
    FC_mean2 = FC_all2.mean(axis=0)
    
 
    df_mean1 = pd.DataFrame(FC_mean1, index=ch_names, columns=ch_names)
    df_mean2 = pd.DataFrame(FC_mean2, index=ch_names, columns=ch_names)
    
    df_mean1.to_csv(os.path.join(save_dir, 'group_mean_condition1_fc.csv'))
    df_mean2.to_csv(os.path.join(save_dir, 'group_mean_condition2_fc.csv'))
    
    print("The average linkage matrix of the grouped data has been saved.")
    
 
    print(" ...")
    
    fig, axes = plt.subplots(1, 2, figsize=(20, 8))
    
    # 确定颜色范围
    vmin = min(FC_mean1.min(), FC_mean2.min())
    vmax = max(FC_mean1.max(), FC_mean2.max())
    
 
    im1 = axes[0].imshow(FC_mean1, cmap='hot', aspect='auto', vmin=vmin, vmax=vmax)
    axes[0].set_title('Group Mean: Condition 1 (闭眼)', fontsize=16)
    axes[0].set_xlabel('Channels', fontsize=12)
    axes[0].set_ylabel('Channels', fontsize=12)
    plt.colorbar(im1, ax=axes[0], fraction=0.046, pad=0.04)
    
 
    im2 = axes[1].imshow(FC_mean2, cmap='hot', aspect='auto', vmin=vmin, vmax=vmax)
    axes[1].set_title('Group Mean: Condition 2 (睁眼)', fontsize=16)
    axes[1].set_xlabel('Channels', fontsize=12)
    axes[1].set_ylabel('Channels', fontsize=12)
    plt.colorbar(im2, ax=axes[1], fraction=0.046, pad=0.04)
    
    plt.tight_layout()
    
 
    plt.savefig(os.path.join(plot_dir, 'group_mean_fc_matrices.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
 
    print("Construction of the group difference matrix (Condition 2 - Condition 1)...")
    
    FC_diff = FC_mean2 - FC_mean1
    
    plt.figure(figsize=(12, 10))
    
 
    max_abs = np.max(np.abs(FC_diff))
    im = plt.imshow(FC_diff, cmap='RdBu_r', aspect='auto', vmin=-max_abs, vmax=max_abs)
    plt.title('Group Difference (Condition 2 - Condition 1)', fontsize=16)
    plt.xlabel('Channels', fontsize=12)
    plt.ylabel('Channels', fontsize=12)
    
 
    cbar = plt.colorbar(im, fraction=0.046, pad=0.04)
    cbar.set_label('FC Difference', fontsize=12)
    
    plt.tight_layout()
    plt.savefig(os.path.join(plot_dir, 'group_difference_fc_matrix.png'), dpi=300, bbox_inches='tight')
    plt.close()
    
 
    df_diff = pd.DataFrame(FC_diff, index=ch_names, columns=ch_names)
    df_diff.to_csv(os.path.join(save_dir, 'group_difference_fc.csv'))
    
else:
    print("The data is not in matrix form, so the group average cannot be calculated.")

 
print("\n ...")

summary_info = {
    'Number of Subjects': FC_all1.shape[0],
    'Number of Channels': n_channels,
    'Condition 1 Name': 'EC',
    'Condition 2 Name': 'EO',
    'Data Shape (per subject)': f'{n_channels} × {n_channels}',
    'Files Saved': f'{FC_all1.shape[0]*2} individual matrices + group averages',
    'Plot Directory': plot_dir
}

df_summary = pd.DataFrame(list(summary_info.items()), columns=['Parameter', 'Value'])
df_summary.to_csv(os.path.join(save_dir, 'analysis_summary.csv'), index=False)

print(f"\n  {save_dir}")
print(f" {plot_dir}")

print("\n :")
csv_count = 0
plot_count = 0

for root, dirs, files in os.walk(save_dir):
    for file in files:
        filepath = os.path.join(root, file)
        if file.endswith('.csv'):
            csv_count += 1
            if root == save_dir:   
                print(f"  - {file}")
        elif file.endswith('.png'):
            plot_count += 1
            if 'plots' in root:   
                rel_path = os.path.relpath(filepath, save_dir)
                print(f"  - {rel_path}")

print(f"\n: {csv_count} 个CSV, {plot_count} png")